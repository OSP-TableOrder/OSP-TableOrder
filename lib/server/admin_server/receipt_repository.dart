import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/models/admin/receipt_status.dart';
import 'package:table_order/models/admin/table_order_info.dart';
import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/server/admin_server/menu_repository.dart';

/// 영수증(Receipt) 도메인 Repository
/// Receipts 컬렉션의 CRUD 및 Firestore 데이터 접근을 담당하는 계층
///
/// 구조:
/// - 정규화됨: Orders 컬렉션이 유일한 주문 데이터 소스
/// - Receipts: 최소 정보 유지 (orderId, totalPrice, status)
/// - 메뉴 정보: Orders.items[].menuId 참조로 조회
class ReceiptRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MenuRepository _menuRepository = MenuRepository();
  static const String _receiptsCollection = 'Receipts';
  static const String _ordersCollection = 'Orders';
  static const String _tablesCollection = 'Tables';

  /// 특정 가게의 모든 미정산 영수증 조회 (테이블별 그룹화)
  Future<List<TableOrderInfo>> fetchUnpaidReceiptsByStore(String storeId) async {
    try {
      developer.log(
        'Fetching unpaid receipts for storeId=$storeId',
        name: 'ReceiptRepository',
      );

      // Receipts 컬렉션에서 status가 'unpaid'인 영수증 조회
      final receiptsSnapshot = await _firestore
          .collection(_receiptsCollection)
          .where('status', isEqualTo: ReceiptStatus.unpaid.value)
          .where('storeId', isEqualTo: storeId)
          .orderBy('createdAt', descending: true)
          .get();

      // Tables 컬렉션에서 테이블 목록 조회
      final tablesSnapshot = await _firestore
          .collection(_tablesCollection)
          .where('storeId', isEqualTo: storeId)
          .get();

      final tableMap = <String, String>{}; // tableId -> tableName
      for (final doc in tablesSnapshot.docs) {
        final data = doc.data();
        tableMap[doc.id] = data['name'] ?? '테이블';
      }

      // 테이블별로 영수증들을 그룹화
      final tableReceiptsMap = <String, List<TableOrder>>{};

      // N+1 쿼리 최적화: 모든 영수증의 Orders를 병렬로 조회
      final receiptFutures = <Future<Map<String, dynamic>>>[
        for (final receiptDoc in receiptsSnapshot.docs)
          _fetchOrdersByReceiptWithMetadata(receiptDoc.id, receiptDoc.data()),
      ];

      // 모든 Orders 조회를 병렬로 기다림
      final receiptOrdersList = await Future.wait(receiptFutures);

      // 영수증과 주문 데이터 병합
      for (int i = 0; i < receiptsSnapshot.docs.length; i++) {
        final receiptDoc = receiptsSnapshot.docs[i];
        final data = receiptDoc.data();
        final tableId = data['tableId'] as String?;

        if (tableId == null) continue;

        final tableName = tableMap[tableId] ?? tableId;
        final ordersMetadata = receiptOrdersList[i];
        final orderEntries = (ordersMetadata['orders'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();

        orderEntries.sort((a, b) {
          final aTs = a['createdAt'] as Timestamp?;
          final bTs = b['createdAt'] as Timestamp?;
          final aMillis = aTs?.millisecondsSinceEpoch ?? 0;
          final bMillis = bTs?.millisecondsSinceEpoch ?? 0;
          return bMillis.compareTo(aMillis);
        });

        if (orderEntries.isEmpty) {
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
          final orderTotalPrice = entry['totalPrice'] as int? ??
              _calculateTotalFromItems(items);

          final hasNewItem = items.any((item) {
            if (item is! Map<String, dynamic>) return false;
            final status = (item['status'] as String? ?? '').toUpperCase();
            return status == 'ORDERED';
          });

          final tableOrder = TableOrder(
            orderId: receiptDoc.id,
            actualOrderId: actualOrderId,
            tableId: tableId,
            tableName: tableName,
            items: items,
            orderTime: _formatTime(createdAt),
            totalPrice: orderTotalPrice,
            hasNewOrder: hasNewItem,
            orderStatus:
                hasNewItem ? OrderStatus.ordered : OrderStatus.empty,
          );

          if (!tableReceiptsMap.containsKey(tableId)) {
            tableReceiptsMap[tableId] = [];
          }
          tableReceiptsMap[tableId]!.add(tableOrder);
        }
      }

      // TableOrderInfo 리스트 생성
      final result = <TableOrderInfo>[];
      for (final entry in tableReceiptsMap.entries) {
        final tableId = entry.key;
        final orders = entry.value;

        final tableOrderInfo = TableOrderInfo(
          tableId: tableId,
          tableName: tableMap[tableId] ?? tableId,
          orders: orders,
        );

        result.add(tableOrderInfo);
      }

      developer.log(
        'Fetched ${result.length} tables with unpaid receipts',
        name: 'ReceiptRepository',
      );

      return result;
    } catch (e) {
      developer.log(
        'Error fetching unpaid receipts: $e',
        name: 'ReceiptRepository',
      );
      return [];
    }
  }

  /// 영수증 상태 변경 (unpaid -> paid)
  Future<bool> updateReceiptStatus({
    required String receiptId,
    required String newStatus,
  }) async {
    try {
      final docRef = _firestore.collection(_receiptsCollection).doc(receiptId);
      final doc = await docRef.get();

      if (!doc.exists) {
        developer.log('Receipt $receiptId not found', name: 'ReceiptRepository');
        return false;
      }

      await docRef.update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Updated receipt status: receiptId=$receiptId, newStatus=$newStatus',
        name: 'ReceiptRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error updating receipt status: $e', name: 'ReceiptRepository');
      return false;
    }
  }

  /// 특정 영수증 조회 (ID로)
  Future<Map<String, dynamic>?> getReceiptById(String receiptId) async {
    try {
      final doc = await _firestore.collection(_receiptsCollection).doc(receiptId).get();

      if (!doc.exists) {
        developer.log('Receipt $receiptId not found', name: 'ReceiptRepository');
        return null;
      }

      return doc.data();
    } catch (e) {
      developer.log('Error fetching receipt: $e', name: 'ReceiptRepository');
      return null;
    }
  }

  /// 영수증 생성
  Future<String?> createReceipt({
    required String storeId,
    required String tableId,
    required int totalPrice,
  }) async {
    try {
      final receiptRef = _firestore.collection(_receiptsCollection).doc();

      await receiptRef.set({
        'storeId': storeId,
        'tableId': tableId,
        'status': ReceiptStatus.unpaid.value,
        'totalPrice': totalPrice,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Created receipt: ${receiptRef.id}',
        name: 'ReceiptRepository',
      );

      return receiptRef.id;
    } catch (e) {
      developer.log('Error creating receipt: $e', name: 'ReceiptRepository');
      return null;
    }
  }

  // ============= Normalized Orders 배열 관련 메서드 =============
  // (MenuMigration 이후 사용되는 정규화된 구조)

  /// Receipt에 Order ID 추가
  Future<bool> addOrderToReceipt({
    required String receiptId,
    required String orderId,
  }) async {
    try {
      final docRef = _firestore.collection(_receiptsCollection).doc(receiptId);
      final doc = await docRef.get();

      if (!doc.exists) {
        developer.log('Receipt $receiptId not found', name: 'ReceiptRepository');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final orders = List<String>.from(
        (data['orders'] as List<dynamic>? ?? []).cast<String>(),
      );

      // 중복 체크
      if (orders.contains(orderId)) {
        developer.log(
          'Order $orderId already in receipt $receiptId',
          name: 'ReceiptRepository',
        );
        return true;
      }

      orders.add(orderId);

      await docRef.update({
        'orders': orders,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Added order to receipt: receiptId=$receiptId, orderId=$orderId',
        name: 'ReceiptRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error adding order to receipt: $e', name: 'ReceiptRepository');
      return false;
    }
  }

  /// Receipt의 Orders 배열에서 Order ID 제거
  Future<bool> removeOrderFromReceipt({
    required String receiptId,
    required String orderId,
  }) async {
    try {
      final docRef = _firestore.collection(_receiptsCollection).doc(receiptId);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final orders = List<String>.from(
        (data['orders'] as List<dynamic>? ?? []).cast<String>(),
      );

      orders.remove(orderId);

      await docRef.update({
        'orders': orders,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Removed order from receipt: receiptId=$receiptId, orderId=$orderId',
        name: 'ReceiptRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error removing order from receipt: $e', name: 'ReceiptRepository');
      return false;
    }
  }

  /// Receipt에 속한 모든 Order 조회 (정규화된 구조)
  /// Receipt.orders 배열의 Order ID들을 사용하여 Orders 컬렉션에서 조회
  Future<List<Map<String, dynamic>>> getOrdersByReceipt(String receiptId) async {
    try {
      final doc = await _firestore
          .collection(_receiptsCollection)
          .doc(receiptId)
          .get();

      if (!doc.exists) {
        developer.log('Receipt $receiptId not found', name: 'ReceiptRepository');
        return [];
      }

      final data = doc.data() as Map<String, dynamic>;
      final orderIds = (data['orders'] as List<dynamic>? ?? [])
          .map((id) => id as String)
          .toList();

      if (orderIds.isEmpty) {
        return [];
      }

      // Orders를 배치로 조회 (Firestore 'in' 쿼리는 최대 10개 지원)
      final orders = <Map<String, dynamic>>[];
      const maxBatchSize = 10;

      for (var i = 0; i < orderIds.length; i += maxBatchSize) {
        final batch = orderIds.sublist(
          i,
          (i + maxBatchSize > orderIds.length) ? orderIds.length : i + maxBatchSize,
        );

        final snapshot = await _firestore
            .collection(_ordersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .orderBy('createdAt', descending: true)
            .get();

        for (final doc in snapshot.docs) {
          orders.add({...doc.data(), 'id': doc.id});
        }
      }

      developer.log(
        'Fetched ${orders.length} orders for receipt $receiptId',
        name: 'ReceiptRepository',
      );

      return orders;
    } catch (e) {
      developer.log('Error fetching orders by receipt: $e', name: 'ReceiptRepository');
      return [];
    }
  }

  /// Receipt에 속한 모든 Order의 메뉴 항목 조회 (메뉴 정보 포함)
  /// UI에서 표시할 수 있는 형식으로 반환
  ///
  /// 반환 값: `{'orders': List<Map<String, dynamic>>, 'receiptId': String}`
  /// - orders: 각 Order 문서를 나타내는 {orderId, items, createdAt, totalPrice}
  /// - receiptId: 영수증 ID
  Future<Map<String, dynamic>> getOrdersByReceiptId(String receiptId) async {
    try {
      final doc = await _firestore
          .collection(_receiptsCollection)
          .doc(receiptId)
          .get();

      if (!doc.exists) {
        developer.log('Receipt $receiptId not found', name: 'ReceiptRepository');
        return {'orders': <Map<String, dynamic>>[], 'receiptId': receiptId};
      }

      final data = doc.data() as Map<String, dynamic>;
      final metadata = await _fetchOrdersByReceiptWithMetadata(receiptId, data);

      return metadata;
    } catch (e) {
      developer.log('Error fetching orders by receipt: $e', name: 'ReceiptRepository');
      return {'orders': <Map<String, dynamic>>[], 'receiptId': receiptId};
    }
  }

  /// Receipt에 orders 배열이 있는지 확인 (정규화 상태 확인)
  Future<bool> hasOrdersArray(String receiptId) async {
    try {
      final doc = await _firestore
          .collection(_receiptsCollection)
          .doc(receiptId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      return data.containsKey('orders');
    } catch (e) {
      developer.log('Error checking orders array: $e', name: 'ReceiptRepository');
      return false;
    }
  }

  /// 메뉴를 Receipt의 최신 Order에 추가
  /// Orders 컬렉션의 메뉴 항목에 직접 추가
  Future<bool> addMenuToReceipt({
    required String receiptId,
    required Map<String, dynamic> menuData,
  }) async {
    try {
      final receiptRef = _firestore.collection(_receiptsCollection).doc(receiptId);
      final receiptDoc = await receiptRef.get();

      if (!receiptDoc.exists) {
        developer.log('Receipt $receiptId not found', name: 'ReceiptRepository');
        return false;
      }

      final receiptData = receiptDoc.data() as Map<String, dynamic>;

      // Receipt의 orders 배열에서 최신 Order ID 가져오기
      final orderIds = (receiptData['orders'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .where((id) => id.isNotEmpty)
          .toList();

      if (orderIds.isEmpty) {
        developer.log(
          'No orders found in receipt $receiptId',
          name: 'ReceiptRepository',
        );
        return false;
      }

      // 최신 Order는 배열의 마지막 요소
      final latestOrderId = orderIds.last;

      // Orders 컬렉션에서 해당 Order 문서 가져오기
      final orderRef = _firestore.collection(_ordersCollection).doc(latestOrderId);
      final orderDoc = await orderRef.get();

      if (!orderDoc.exists) {
        developer.log(
          'Order $latestOrderId not found in Orders collection',
          name: 'ReceiptRepository',
        );
        return false;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(
        (orderData['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      // 새 메뉴 항목 생성
      final newMenuItem = {
        'menuId': menuData['id'] ?? '',
        'quantity': menuData['quantity'] ?? 1,
        'status': 'ORDERED',
        'completedCount': 0,
        'orderedAt': Timestamp.fromDate(DateTime.now()),
        'priceAtOrder': menuData['price'] ?? 0,
      };

      items.add(newMenuItem);

      // totalPrice 재계산
      int newTotalPrice = 0;
      for (final item in items) {
        final status = (item['status'] as String?)?.toUpperCase() ?? '';
        if (status != 'CANCELED') {
          newTotalPrice += ((item['priceAtOrder'] as int?) ?? 0) *
              ((item['quantity'] as int?) ?? 1);
        }
      }

      // Orders 컬렉션의 해당 Order 업데이트
      await orderRef.update({
        'items': items,
        'totalPrice': newTotalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Receipt의 totalPrice도 업데이트
      final quantity = (menuData['quantity'] as int?) ?? 1;
      final price = (menuData['price'] as int?) ?? 0;
      final receiptTotalPrice = ((receiptData['totalPrice'] as int?) ?? 0) + (price * quantity);

      await receiptRef.update({
        'totalPrice': receiptTotalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Added menu to order: receiptId=$receiptId, orderId=$latestOrderId, menuName=${menuData['name']}',
        name: 'ReceiptRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error adding menu to receipt: $e', name: 'ReceiptRepository');
      return false;
    }
  }

  // ============= Private 메서드 =============

  /// Receipt 문서에서 메뉴 항목 추출 (N+1 쿼리 최적화)
  /// Receipt 문서는 이미 로드되었으므로 receiptData에서 직접 추출
  ///
  /// 우선순위:
  /// 1. Receipts.menus[]가 있으면 그것을 사용 (레거시 데이터)
  /// 2. Receipts.menus[]가 없으면 Orders 컬렉션에서 menuId 기반 추출
  Future<Map<String, dynamic>> _fetchOrdersByReceiptWithMetadata(
    String receiptId,
    Map<String, dynamic> receiptData,
  ) async {
    try {
      final orderEntries = <Map<String, dynamic>>[];

      // 1. Receipts.orders[] 배열이 있으면 각 Order 문서를 개별 주문으로 처리
      final orderIds = (receiptData['orders'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .where((id) => id.isNotEmpty)
          .toList();

      if (orderIds.isNotEmpty) {
        for (final orderId in orderIds) {
          final entry = await _buildOrderEntry(orderId);
          if (entry != null) {
            orderEntries.add(entry);
          }
        }
      }

      // 2. 단일 orderId 필드를 사용 (레거시)
      if (orderEntries.isEmpty) {
        final singleOrderId = receiptData['orderId'] as String?;
        if (singleOrderId != null && singleOrderId.isNotEmpty) {
          final entry = await _buildOrderEntry(singleOrderId);
          if (entry != null) {
            orderEntries.add(entry);
          }
        }
      }

      // 3. Legacy Receipts.menus[]에서 직접 추출
      if (orderEntries.isEmpty) {
        final legacyItems = _extractMenusFromReceipt(receiptData);
        if (legacyItems.isNotEmpty) {
          orderEntries.add({
            'orderId': receiptId,
            'items': legacyItems,
            'createdAt': receiptData['createdAt'],
            'totalPrice': (receiptData['totalPrice'] as int?) ??
                _calculateTotalFromItems(legacyItems),
          });
        }
      }

      return {
        'receiptId': receiptId,
        'orders': orderEntries,
      };
    } catch (e) {
      developer.log(
        'Error extracting orders from receipt $receiptId: $e',
        name: 'ReceiptRepository',
      );
      return {
        'receiptId': receiptId,
        'orders': <Map<String, dynamic>>[],
      };
    }
  }

  /// Receipt 문서에서 메뉴 항목을 추출하여 표시용 형식으로 변환
  ///
  /// 주의: Receipts.menus[]는 이제 비어있음 (Orders 컬렉션으로 완전 이동)
  /// 이 메서드는 레거시 지원을 위해 유지되지만,
  /// 실제로는 _extractMenusFromOrders()가 사용됨
  List<dynamic> _extractMenusFromReceipt(Map<String, dynamic> receiptData) {
    final menus = receiptData['menus'] as List<dynamic>? ?? [];

    // Receipts.menus[]가 비어있으면 빈 배열 반환
    if (menus.isEmpty) {
      return [];
    }

    // 레거시: 이전 데이터 지원
    final items = <dynamic>[];
    for (final menu in menus) {
      if (menu is Map<String, dynamic>) {
        final menuInfo = menu['menu'] as Map<String, dynamic>? ?? {};

        // orderedAt 타임스탬프 파싱
        String? orderedAtStr;
        final orderedAtTimestamp = menu['orderedAt'] as Timestamp?;
        if (orderedAtTimestamp != null) {
          final dateTime = orderedAtTimestamp.toDate();
          final hour = dateTime.hour.toString().padLeft(2, '0');
          final minute = dateTime.minute.toString().padLeft(2, '0');
          final second = dateTime.second.toString().padLeft(2, '0');
          orderedAtStr = '$hour:$minute:$second';
        }

        items.add({
          'name': menuInfo['name'] ?? '미정의',
          'price': menuInfo['price'] ?? 0,
          'quantity': menu['quantity'] ?? 1,
          'status': menu['status'] ?? 'ordered',
          'orderedAt': orderedAtStr,
        });
      }
    }

    return items;
  }

  Future<Map<String, dynamic>?> _buildOrderEntry(String orderId) async {
    if (orderId.isEmpty) return null;

    try {
      final orderDoc =
          await _firestore.collection(_ordersCollection).doc(orderId).get();
      if (!orderDoc.exists) {
        return null;
      }

      final data = orderDoc.data() as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      final displayItems = await _mapOrderItemsWithMenuInfo(items, orderId);

      return {
        'orderId': orderId,
        'items': displayItems,
        'createdAt': data['createdAt'] as Timestamp?,
        'totalPrice': (data['totalPrice'] as int?) ?? 0,
      };
    } catch (e) {
      developer.log(
        'Error building order entry for $orderId: $e',
        name: 'ReceiptRepository',
      );
      return null;
    }
  }

  Future<List<dynamic>> _mapOrderItemsWithMenuInfo(
    List<dynamic> items,
    String orderId,
  ) async {
    final menuIds = <String>{};
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        final menuId = item['menuId'] as String?;
        if (menuId != null && menuId.isNotEmpty) {
          menuIds.add(menuId);
        }
      }
    }

    final menus = menuIds.isEmpty
        ? <Menu>[]
        : await _menuRepository.getMenusByIds(menuIds.toList());
    final menuMap = <String, Map<String, dynamic>>{};
    for (final menu in menus) {
      menuMap[menu.id] = {
        'name': menu.name,
        'price': menu.price,
      };
    }

    final displayItems = <dynamic>[];

    for (int index = 0; index < items.length; index++) {
      final item = items[index];
      if (item is Map<String, dynamic>) {
        final menuId = item['menuId'] as String?;
        final quantity = item['quantity'] as int? ?? 1;
        final status = item['status'] as String? ?? 'ordered';
        final orderedAtTimestamp = item['orderedAt'] as Timestamp?;
        final priceAtOrder = item['priceAtOrder'] as int? ?? 0;

        String? orderedAtStr;
        if (orderedAtTimestamp != null) {
          final dateTime = orderedAtTimestamp.toDate();
          orderedAtStr =
              '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
        }

        final menuInfo = menuId != null ? menuMap[menuId] : null;
        final menuName = menuInfo?['name'] ?? '미정의';

        displayItems.add({
          'menuId': menuId,
          'quantity': quantity,
          'status': status,
          'orderedAt': orderedAtStr,
          'priceAtOrder': priceAtOrder,
          'name': menuName,
          'price': priceAtOrder,
          'sourceOrderId': orderId,
          'sourceItemIndex': index,
        });
      }
    }

    return displayItems;
  }

  /// 시간 포맷팅
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '-';

    final dateTime = timestamp.toDate();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _calculateTotalFromItems(List<dynamic> items) {
    int total = 0;
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        final price = item['price'] ?? item['priceAtOrder'] ?? 0;
        final quantity = item['quantity'] ?? 0;
        total += (price as int) * (quantity as int);
      }
    }
    return total;
  }
}
