import 'dart:developer' as developer;

import 'package:flutter/material.dart';
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

  List<TableOrderInfo> _tables = [];
  bool _loading = false;
  String? _error;

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

        // Firestore에 저장
        final success = await _orderService.updateMenuQuantity(
          orderId: order.orderId,
          menuIndex: itemIndex,
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

        // Firestore에 저장
        final success = await _orderService.updateMenuStatus(
          orderId: order.orderId,
          menuIndex: itemIndex,
          newStatus: newStatus,
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
      order.items.removeAt(itemIndex);
      _updateOrderStatus(order);
      notifyListeners();

      // Firestore에 저장
      final success = await _orderService.removeMenu(
        orderId: order.orderId,
        menuIndex: itemIndex,
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
        'status': 'ordered',
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

      // Firestore에 메뉴 추가 (Receipt.menus[] 배열에 추가)
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
        newStatus: 'paid',
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
    for (final item in order.items) {
      if (item is Map) {
        final price = item['price'] ?? 0;
        final quantity = item['quantity'] ?? 0;
        total += (price as int) * (quantity as int);
      }
    }
    order.totalPrice = total;

    // 주문이 있으면 상태 변경
    if (order.items.isNotEmpty) {
      order.orderStatus = OrderStatus.ordered;
    } else {
      order.orderStatus = OrderStatus.empty;
    }
  }

  /// 상태 전환 가능 여부 확인
  bool _canTransitionStatus(String currentStatus, String newStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'ordered':
        return newStatus == 'cooking' || newStatus == 'canceled';
      case 'cooking':
        return newStatus == 'completed' || newStatus == 'canceled';
      case 'completed':
      case 'canceled':
        return false;
      default:
        return false;
    }
  }

  /// 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
