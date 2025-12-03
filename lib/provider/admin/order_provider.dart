import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_order/models/admin/receipt_status.dart';
import 'package:table_order/models/admin/table_order_info.dart';
import 'package:table_order/service/admin/order_service.dart';
import 'package:table_order/service/admin/receipt_service.dart';
import 'package:table_order/service/admin/staff_request_service.dart';
import 'package:table_order/service/admin/store_service.dart';

/// 주문 도메인 Provider
/// 테이블별 주문 정보와 UI 상태 관리
class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  final ReceiptService _receiptService = ReceiptService();
  final StaffRequestService _staffRequestService = StaffRequestService();
  final StoreService _storeService = StoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<TableOrderInfo> _tables = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _receiptsListener;
  StreamSubscription<QuerySnapshot>? _ordersListener;
  StreamSubscription<QuerySnapshot>? _callRequestsListener;

  // Getters
  List<TableOrderInfo> get tables => _tables;
  bool get loading => _loading;
  String? get error => _error;

  // ============= 데이터 로드 메서드 =============

  /// 특정 가게의 미정산 주문을 테이블별로 조회하여 로드
  Future<void> loadTables(String storeId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      developer.log(
        'Loading tables for storeId=$storeId',
        name: 'OrderProvider',
      );

      // 1) 테이블 목록 조회 (StoreService 사용)
      final tableModels = await _storeService.getTables(storeId);
      developer.log(
        'Found ${tableModels.length} tables',
        name: 'OrderProvider',
      );

      // 2) 미정산 영수증 조회 (ReceiptService 사용)
      final ordersFromFirestore = await _receiptService.getUnpaidReceiptsByStore(storeId);
      developer.log(
        'Found ${ordersFromFirestore.length} tables with unpaid receipts',
        name: 'OrderProvider',
      );

      // 3) 직원 호출 목록 조회
      final callRequests = await _staffRequestService.getLogs(storeId);
      final tablesWithCallRequest = callRequests
          .where((log) => !log.resolved)
          .map((log) => log.tableId)
          .toSet();

      // 4) 테이블별로 주문 정보 병합
      final tableOrderMap = <String, TableOrderInfo>{};
      for (final order in ordersFromFirestore) {
        developer.log(
          'Adding receipt to map: tableId=${order.tableId}, tableName=${order.tableName}',
          name: 'OrderProvider',
        );
        tableOrderMap[order.tableId] = order;
      }

      _tables = tableModels.map((tableModel) {
        developer.log(
          'Mapping tableModel: id=${tableModel.id}, name=${tableModel.name}',
          name: 'OrderProvider',
        );

        // Firestore의 주문 데이터가 있으면 사용, 없으면 빈 테이블
        final found = tableOrderMap[tableModel.id];
        if (found != null) {
          developer.log(
            'Found ${found.orders.length} receipt(s) for table ${tableModel.name}',
            name: 'OrderProvider',
          );
          found.hasCallRequest = tablesWithCallRequest.contains(found.tableId);
          return found;
        } else {
          developer.log(
            'No receipt found for table ${tableModel.name}',
            name: 'OrderProvider',
          );
          return TableOrderInfo(
            tableId: tableModel.id,
            tableName: tableModel.name,
            hasCallRequest: tablesWithCallRequest.contains(tableModel.id),
          );
        }
      }).toList();

      developer.log(
        'Tables loaded: ${_tables.length}',
        name: 'OrderProvider',
      );

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load tables: $e';
      developer.log(_error!, name: 'OrderProvider');
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 미정산 영수증 실시간 리스닝 시작
  /// loadTables() 호출 후 이 메서드를 호출하여 실시간 업데이트 수신
  void startListeningForUnpaidReceipts(String storeId) {
    // 기존 리스너 정리
    _receiptsListener?.cancel();
    _ordersListener?.cancel();
    _callRequestsListener?.cancel();

    try {
      developer.log(
        'Starting Firestore listeners for storeId=$storeId',
        name: 'OrderProvider',
      );

      final unpaidStatus = ReceiptStatus.unpaid.value;

      // 1. Receipts 컬렉션 리스너 (Receipt 생성/삭제 감지)
      _receiptsListener = _firestore
          .collection('Receipts')
          .where('status', isEqualTo: unpaidStatus)
          .where('storeId', isEqualTo: storeId)
          .snapshots()
          .listen(
        (snapshot) async {
          developer.log(
            '🔔 Receipts snapshot received: ${snapshot.docs.length} receipts, '
            'docChanges: ${snapshot.docChanges.length}',
            name: 'OrderProvider',
          );

          // 변경된 문서 정보 로깅
          for (final change in snapshot.docChanges) {
            developer.log(
              '  - ${change.type}: ${change.doc.id}',
              name: 'OrderProvider',
            );
          }

          // 변경된 영수증 데이터 로드
          await _updateTablesFromReceipts(snapshot.docs, storeId);
        },
        onError: (error) {
          developer.log(
            'Error in Receipts listener: $error',
            name: 'OrderProvider',
          );
        },
      );

      // 2. Orders 컬렉션 리스너 (메뉴 추가/변경 감지)
      _ordersListener = _firestore
          .collection('Orders')
          .where('storeId', isEqualTo: storeId)
          .snapshots()
          .listen(
        (snapshot) async {
          developer.log(
            '🔔 Orders snapshot received: ${snapshot.docs.length} orders, '
            'docChanges: ${snapshot.docChanges.length}',
            name: 'OrderProvider',
          );

          // 변경된 문서 정보 로깅
          for (final change in snapshot.docChanges) {
            developer.log(
              '  - ${change.type}: ${change.doc.id}',
              name: 'OrderProvider',
            );
          }

          // Orders가 변경되면 Receipts도 다시 로드
          final receiptsSnapshot = await _firestore
              .collection('Receipts')
              .where('status', isEqualTo: unpaidStatus)
              .where('storeId', isEqualTo: storeId)
              .get();

          await _updateTablesFromReceipts(receiptsSnapshot.docs, storeId);
        },
        onError: (error) {
          developer.log(
            'Error in Orders listener: $error',
            name: 'OrderProvider',
          );
        },
      );

      // 3. CallRequests 컬렉션 리스너 (직원 호출 실시간 표시)
      _callRequestsListener = _firestore
          .collection('CallRequests')
          .where('storeId', isEqualTo: storeId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen(
        (snapshot) {
          developer.log(
            '🔔 CallRequests snapshot received: ${snapshot.docs.length} pending',
            name: 'OrderProvider',
          );
          _applyCallRequestsSnapshot(snapshot);
        },
        onError: (error) {
          developer.log(
            'Error in CallRequests listener: $error',
            name: 'OrderProvider',
          );
        },
      );

      developer.log(
        'Firestore listeners started successfully',
        name: 'OrderProvider',
      );
    } catch (e) {
      developer.log('Error starting listeners: $e', name: 'OrderProvider');
    }
  }

  /// Receipts snapshot으로부터 테이블 데이터 업데이트
  Future<void> _updateTablesFromReceipts(
    List<QueryDocumentSnapshot> receiptDocs,
    String storeId,
  ) async {
    try {
      // 각 영수증의 Orders 정보를 병렬로 가져오기
      final receiptFutures = <Future<Map<String, dynamic>>>[
        for (final receiptDoc in receiptDocs)
          _receiptService.getOrdersByReceiptId(receiptDoc.id).then((metadata) {
            final result = <String, dynamic>{};
            result['receiptId'] = receiptDoc.id;
            result['data'] = receiptDoc.data();
            result['orders'] = metadata['orders'] as List<dynamic>? ?? [];
            return result;
          }).catchError((_) {
            final result = <String, dynamic>{};
            result['receiptId'] = receiptDoc.id;
            result['data'] = receiptDoc.data();
            result['orders'] = <dynamic>[];
            return result;
          }),
      ];

      final receiptDataList = await Future.wait(receiptFutures);

      // 기존 테이블 이름 정보 보존 (StoreService에서 가져온 테이블 정보)
      final existingTableNames = <String, String>{};
      for (final table in _tables) {
        existingTableNames[table.tableId] = table.tableName;
      }

      // 직원 호출 정보 보존
      final existingCallRequests = <String, bool>{};
      for (final table in _tables) {
        existingCallRequests[table.tableId] = table.hasCallRequest;
      }

      // 테이블별로 영수증을 그룹화
      final tableOrdersMap = <String, List<TableOrder>>{};

      for (final receiptData in receiptDataList) {
        final receiptId = receiptData['receiptId'] as String;
        final data = receiptData['data'] as Map<String, dynamic>;
        final orderEntries = (receiptData['orders'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        final tableId = data['tableId'] as String?;

        if (tableId == null) continue;

        // 테이블 이름 결정 (기존 이름 우선, 없으면 Firestore 데이터 사용)
        final tableName = existingTableNames[tableId] ??
            data['tableName'] as String? ??
            tableId;

        orderEntries.sort((a, b) {
          final aTs = a['createdAt'] as Timestamp?;
          final bTs = b['createdAt'] as Timestamp?;
          final aMillis = aTs?.millisecondsSinceEpoch ?? 0;
          final bMillis = bTs?.millisecondsSinceEpoch ?? 0;
          return bMillis.compareTo(aMillis);
        });

        if (orderEntries.isEmpty) {
          // 주문 정보가 없으면 빈 주문 한 개를 추가 (레거시 대비)
          orderEntries.add({
            'orderId': null,
            'items': <dynamic>[],
            'createdAt': data['createdAt'],
            'totalPrice': (data['totalPrice'] as int?) ?? 0,
          });
        }

        for (final entry in orderEntries) {
          final items = (entry['items'] as List<dynamic>? ?? []);
          final actualOrderId = entry['orderId'] as String?;
          final createdAt = entry['createdAt'] as Timestamp? ??
              data['createdAt'] as Timestamp?;
          final entryTotalPrice = entry['totalPrice'] as int? ??
              _calculateTotalFromItems(items);

          final hasNewItemInThisOrder = items.any((item) {
            if (item is! Map<String, dynamic>) return false;
            final status = (item['status'] as String? ?? '').toUpperCase();
            return status == 'ORDERED';
          });

          final tableOrder = TableOrder(
            orderId: receiptId,
            actualOrderId: actualOrderId,
            tableId: tableId,
            tableName: tableName,
            items: items,
            orderTime: _formatTime(createdAt),
            totalPrice: entryTotalPrice,
            hasNewOrder: hasNewItemInThisOrder,
            orderStatus:
                hasNewItemInThisOrder ? OrderStatus.ordered : OrderStatus.empty,
          );

          if (!tableOrdersMap.containsKey(tableId)) {
            tableOrdersMap[tableId] = [];
          }
          tableOrdersMap[tableId]!.add(tableOrder);
        }
      }

      // 새로운 테이블 목록 생성 (기존 테이블 구조 유지)
      final updatedTables = <TableOrderInfo>[];

      // 기존 테이블을 순회하며 업데이트
      for (final existingTable in _tables) {
        final tableId = existingTable.tableId;
        final ordersForTable = tableOrdersMap[tableId] ?? [];

        updatedTables.add(TableOrderInfo(
          tableId: tableId,
          tableName: existingTable.tableName,
          orders: ordersForTable,
          hasCallRequest: existingCallRequests[tableId] ?? false,
        ));

        // 처리된 테이블은 맵에서 제거
        tableOrdersMap.remove(tableId);
      }

      // 새로 생긴 테이블 추가 (기존 목록에 없던 테이블)
      for (final entry in tableOrdersMap.entries) {
        final tableId = entry.key;
        final orders = entry.value;
        final tableName = orders.isNotEmpty
            ? orders.first.tableName
            : tableId;

        updatedTables.add(TableOrderInfo(
          tableId: tableId,
          tableName: tableName,
          orders: orders,
          hasCallRequest: false,
        ));
      }

      _tables = updatedTables;

      developer.log(
        'Updated tables from receipts: ${_tables.length} tables, ${receiptDocs.length} receipts',
        name: 'OrderProvider',
      );

      notifyListeners();
    } catch (e) {
      developer.log('Error updating tables from receipts: $e', name: 'OrderProvider');
    }
  }

  /// 리스닝 중지
  void stopListeningForUnpaidReceipts() {
    _receiptsListener?.cancel();
    _receiptsListener = null;
    _ordersListener?.cancel();
    _ordersListener = null;
    _callRequestsListener?.cancel();
    _callRequestsListener = null;
  }

  @override
  void dispose() {
    stopListeningForUnpaidReceipts();
    super.dispose();
  }

  // ============= 메뉴 관리 메서드 =============

  /// 메뉴 수량 변경
  Future<void> updateMenuQuantity(
    int tableIndex,
    int orderIndex,
    int itemIndex,
    int newQuantity,
  ) async {
    if (tableIndex < 0 || tableIndex >= _tables.length) return;

    final table = _tables[tableIndex];
    if (orderIndex < 0 || orderIndex >= table.orders.length) return;

    final order = table.orders[orderIndex];
    if (itemIndex < 0 || itemIndex >= order.items.length) return;
    if (newQuantity < 1) return;

    try {
      final dynamic item = order.items[itemIndex];

      if (item is Map) {
        item['quantity'] = newQuantity;
        _updateOrderStatus(order);
        notifyListeners();

        final target = _resolveMenuTarget(order, item, itemIndex);

        // Firestore에 저장 (source 메타데이터 우선 사용)
        final success = await _orderService.updateMenuQuantity(
          orderId: target.orderId,
          menuIndex: target.menuIndex,
          newQuantity: newQuantity,
        );

        if (!success) {
          _error = 'Failed to update menu quantity';
          developer.log(_error!, name: 'OrderProvider');
          notifyListeners();
        }
      }
    } catch (e) {
      _error = 'Error updating menu quantity: $e';
      developer.log(_error!, name: 'OrderProvider');
      notifyListeners();
    }
  }

  /// 메뉴 상태 변경
  Future<bool> updateMenuStatus(
    int tableIndex,
    int orderIndex,
    int itemIndex,
    String newStatus,
  ) async {
    if (tableIndex < 0 || tableIndex >= _tables.length) return false;

    final table = _tables[tableIndex];
    if (orderIndex < 0 || orderIndex >= table.orders.length) return false;

    final order = table.orders[orderIndex];
    if (itemIndex < 0 || itemIndex >= order.items.length) return false;

    try {
      final dynamic item = order.items[itemIndex];

      if (item is Map) {
        final currentStatus = item['status'] ?? 'ordered';

        // 상태 전환 규칙 검증
        if (!_canTransitionStatus(currentStatus, newStatus)) {
          developer.log(
            'Cannot transition from $currentStatus to $newStatus',
            name: 'OrderProvider',
          );
          return false;
        }

        item['status'] = newStatus;
        notifyListeners();

        final target = _resolveMenuTarget(order, item, itemIndex);

        // Firestore에 저장 (source 정보 우선 사용, status는 대문자로 저장)
        final success = await _orderService.updateMenuStatus(
          orderId: target.orderId,
          menuIndex: target.menuIndex,
          newStatus: newStatus.toUpperCase(),
        );

        if (!success) {
          _error = 'Failed to update menu status';
          developer.log(_error!, name: 'OrderProvider');
          notifyListeners();
          return false;
        }

        return true;
      }

      return false;
    } catch (e) {
      _error = 'Error updating menu status: $e';
      developer.log(_error!, name: 'OrderProvider');
      notifyListeners();
      return false;
    }
  }

  /// 메뉴 제거
  Future<void> removeMenu({
    required int tableIndex,
    required int orderIndex,
    required int itemIndex,
  }) async {
    if (tableIndex < 0 || tableIndex >= _tables.length) return;

    final table = _tables[tableIndex];
    if (orderIndex < 0 || orderIndex >= table.orders.length) return;

    final order = table.orders[orderIndex];
    if (itemIndex < 0 || itemIndex >= order.items.length) return;

    try {
      final dynamic item = order.items[itemIndex];
      order.items.removeAt(itemIndex);
      _updateOrderStatus(order);
      notifyListeners();

      final target = _resolveMenuTarget(order, item, itemIndex);

      // Firestore에 저장 (source 정보 우선 사용)
      final success = await _orderService.removeMenu(
        orderId: target.orderId,
        menuIndex: target.menuIndex,
      );

      if (!success) {
        _error = 'Failed to remove menu';
        developer.log(_error!, name: 'OrderProvider');
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error removing menu: $e';
      developer.log(_error!, name: 'OrderProvider');
      notifyListeners();
    }
  }

  /// 메뉴 추가 (관리자가 직접 추가)
  Future<void> addMenuToReceipt({
    required int tableIndex,
    required int orderIndex,
    required Map<String, dynamic> menuData,
  }) async {
    if (tableIndex < 0 || tableIndex >= _tables.length) return;

    final table = _tables[tableIndex];
    if (orderIndex < 0 || orderIndex >= table.orders.length) return;

    final order = table.orders[orderIndex];

    try {
      // menuData: { id, name, price, quantity, ... }
      final newMenuItem = {
        'name': menuData['name'] ?? '미정의',
        'price': menuData['price'] ?? 0,
        'quantity': menuData['quantity'] ?? 1,
        'status': 'ORDERED',
        'orderedAt': DateTime.now(),
      };

      // UI에 즉시 반영
      order.items.add(newMenuItem);
      _updateOrderStatus(order);
      notifyListeners();

      developer.log(
        'Added menu to receipt: receiptId=${order.orderId}, menu=${menuData['name']}',
        name: 'OrderProvider',
      );

      // Firestore에 메뉴 추가 (Orders 컬렉션의 최신 Order에 메뉴 추가)
      final success = await _receiptService.addMenuToReceipt(
        receiptId: order.orderId,
        menuData: menuData,
      );

      if (!success) {
        _error = 'Failed to save menu to Firestore';
        developer.log(_error!, name: 'OrderProvider');
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error adding menu: $e';
      developer.log(_error!, name: 'OrderProvider');
      notifyListeners();
    }
  }

  // ============= 주문 정산 메서드 =============

  /// 주문 정산 (영수증 상태를 unpaid에서 paid로 변경)
  Future<bool> settleReceipt(int tableIndex, int orderIndex) async {
    try {
      if (tableIndex < 0 || tableIndex >= _tables.length) return false;

      final table = _tables[tableIndex];
      if (orderIndex < 0 || orderIndex >= table.orders.length) return false;

      final order = table.orders[orderIndex];

      developer.log(
        'Settling receipt: ${order.orderId}',
        name: 'OrderProvider',
      );

      final success = await _receiptService.updateReceiptStatus(
        receiptId: order.orderId,
        newStatus: ReceiptStatus.paid.value,
      );

      if (success) {
        developer.log(
          'Receipt ${order.orderId} settled successfully',
          name: 'OrderProvider',
        );
        // 정산된 영수증을 목록에서 제거
        table.orders.removeAt(orderIndex);
        notifyListeners();
      } else {
        _error = 'Failed to settle receipt';
        developer.log(_error!, name: 'OrderProvider');
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Error settling receipt: $e';
      developer.log(_error!, name: 'OrderProvider');
      notifyListeners();
      return false;
    }
  }

  // ============= 호출 요청 메서드 =============

  /// 직원 호출 요청 확인 (pending -> resolved)
  Future<void> checkCallRequest(int tableIndex, String storeId) async {
    if (tableIndex < 0 || tableIndex >= _tables.length) return;

    final table = _tables[tableIndex];
    try {
      await _staffRequestService.resolveCallRequests(
        storeId: storeId,
        tableId: table.tableId,
      );

      table.hasCallRequest = false;
      notifyListeners();

      developer.log(
        'Call request resolved for tableId=${table.tableId}',
        name: 'OrderProvider',
      );
    } catch (e) {
      _error = 'Failed to resolve call request: $e';
      developer.log(_error!, name: 'OrderProvider');
      notifyListeners();
    }
  }

  // ============= Private 메서드 =============

  /// 주문의 총 가격 및 상태 업데이트
  void _updateOrderStatus(TableOrder order) {
    int total = 0;
    bool hasOrderedItem = false;
    for (final item in order.items) {
      if (item is Map) {
        final price = item['price'] ?? 0;
        final quantity = item['quantity'] ?? 0;
        final status = (item['status'] as String? ?? '').toUpperCase();
        if (status == 'ORDERED') {
          hasOrderedItem = true;
        }
        total += (price as int) * (quantity as int);
      }
    }
    order.totalPrice = total;

    order.hasNewOrder = hasOrderedItem;
    order.orderStatus = hasOrderedItem ? OrderStatus.ordered : OrderStatus.empty;
  }

  int _calculateTotalFromItems(List<dynamic> items) {
    int total = 0;
    for (final item in items) {
      if (item is Map) {
        final dynamic price = item['price'] ?? item['priceAtOrder'] ?? 0;
        final dynamic quantity = item['quantity'] ?? 0;
        total += (price as int) * (quantity as int);
      }
    }
    return total;
  }

  /// 상태 전환 가능 여부 확인
  bool _canTransitionStatus(String currentStatus, String newStatus) {
    final current = currentStatus.toUpperCase();
    final next = newStatus.toUpperCase();

    switch (current) {
      case 'ORDERED':
        return next == 'COOKING' || next == 'CANCELED';
      case 'COOKING':
        return next == 'COMPLETED' || next == 'CANCELED';
      case 'COMPLETED':
      case 'CANCELED':
        return false;
      default:
        return false;
    }
  }

  /// Timestamp를 시간 문자열로 포맷
  String? _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return null;
    final dateTime = timestamp.toDate();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 직원 호출 스냅샷을 기반으로 hasCallRequest 갱신
  void _applyCallRequestsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    try {
      final tablesWithCall = snapshot.docs
          .map((doc) {
            final tableId = doc.data()['tableId'] as String?;
            return tableId;
          })
          .whereType<String>()
          .toSet();

      var changed = false;
      for (final table in _tables) {
        final hasRequest = tablesWithCall.contains(table.tableId);
        if (table.hasCallRequest != hasRequest) {
          table.hasCallRequest = hasRequest;
          changed = true;
        }
      }

      if (changed) {
        notifyListeners();
      }
    } catch (e) {
      developer.log(
        'Error applying call request snapshot: $e',
        name: 'OrderProvider',
      );
    }
  }

  /// 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 메뉴 항목이 속한 실제 Order ID와 item index를 계산
  _MenuTarget _resolveMenuTarget(
    TableOrder order,
    dynamic item,
    int fallbackIndex,
  ) {
    if (item is Map) {
      final sourceOrderId = item['sourceOrderId'] as String?;
      final sourceItemIndex = item['sourceItemIndex'];
      if (sourceOrderId != null &&
          sourceOrderId.isNotEmpty &&
          sourceItemIndex is int) {
        return _MenuTarget(
          sourceOrderId,
          sourceItemIndex,
        );
      }
    }

    final fallbackOrderId = order.actualOrderId ?? order.orderId;
    return _MenuTarget(fallbackOrderId, fallbackIndex);
  }
}

class _MenuTarget {
  final String orderId;
  final int menuIndex;
  _MenuTarget(this.orderId, this.menuIndex);
}
