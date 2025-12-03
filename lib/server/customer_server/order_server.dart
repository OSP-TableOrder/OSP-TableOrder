import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:table_order/models/admin/receipt_status.dart';
import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/models/admin/order.dart' as order_model;
import 'package:table_order/models/customer/order.dart';
import 'package:table_order/models/customer/order_menu.dart';
import 'package:table_order/models/common/order_menu_status.dart';
import 'package:table_order/models/customer/order_status.dart';

/// `_OrdersRepository` - 정규화된 Orders 컬렉션 관리
///
/// 역할:
/// - 새로운 정규화된 데이터 구조 지원 (Orders 컬렉션)
/// - menuId 참조 기반 데이터 저장
class _OrdersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _ordersCollection = 'Orders';

  /// 새로운 Order 생성 (정규화된 Orders 컬렉션)
  /// 각 Receipt은 여러 Order를 가질 수 있음
  Future<order_model.Order?> createOrder({
    required String receiptId,
    required String storeId,
    required String tableId,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = _firestore.collection(_ordersCollection).doc();

      await docRef.set({
        'receiptId': receiptId,
        'storeId': storeId,
        'tableId': tableId,
        'items': [],
        'totalPrice': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return order_model.Order(
        id: docRef.id,
        receiptId: receiptId,
        storeId: storeId,
        tableId: tableId,
        items: [],
        totalPrice: 0,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      developer.log('Error creating order: $e', name: 'OrderServer');
      return null;
    }
  }

  /// Order 조회 (ID로)
  Future<order_model.Order?> findById(String orderId) async {
    try {
      final doc = await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .get();

      if (!doc.exists) return null;

      return order_model.Order.fromJson({
        ...doc.data()!,
        'id': doc.id,
      });
    } catch (e) {
      developer.log('Error fetching order: $e', name: 'OrderServer');
      return null;
    }
  }

  /// Receipt에 속한 모든 Order 조회
  Future<List<order_model.Order>> findOrdersByReceiptId(String receiptId) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('receiptId', isEqualTo: receiptId)
          .orderBy('createdAt', descending: true)
          .get();

      final orders = <order_model.Order>[];
      for (final doc in snapshot.docs) {
        try {
          final order = order_model.Order.fromJson({
            ...doc.data(),
            'id': doc.id,
          });
          orders.add(order);
        } catch (e) {
          developer.log(
            'Error parsing order document ${doc.id}: $e',
            name: 'OrderServer',
          );
        }
      }

      developer.log(
        'Fetched ${orders.length} orders for receiptId=$receiptId',
        name: 'OrderServer',
      );

      return orders;
    } catch (e) {
      developer.log('Error fetching orders by receiptId: $e', name: 'OrderServer');
      return [];
    }
  }

  /// 특정 테이블의 모든 unpaid Order 조회
  Future<List<order_model.Order>> findUnpaidOrdersByTable({
    required String storeId,
    required String tableId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('storeId', isEqualTo: storeId)
          .where('tableId', isEqualTo: tableId)
          .orderBy('createdAt', descending: true)
          .get();

      final orders = <order_model.Order>[];
      for (final doc in snapshot.docs) {
        try {
          final order = order_model.Order.fromJson({
            ...doc.data(),
            'id': doc.id,
          });
          orders.add(order);
        } catch (e) {
          developer.log(
            'Error parsing order document ${doc.id}: $e',
            name: 'OrderServer',
          );
        }
      }

      developer.log(
        'Fetched ${orders.length} orders for table $tableId in store $storeId',
        name: 'OrderServer',
      );

      return orders;
    } catch (e) {
      developer.log('Error fetching unpaid orders by table: $e', name: 'OrderServer');
      return [];
    }
  }

  /// Order에 메뉴 항목 추가
  /// menuId를 참조하여 저장 (정규화된 구조)
  Future<order_model.Order?> addMenuItem({
    required String orderId,
    required String menuId,
    required int quantity,
    required int priceAtOrder,
  }) async {
    try {
      final docRef = _firestore.collection(_ordersCollection).doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) {
        developer.log('Order $orderId not found', name: 'OrderServer');
        return null;
      }

      final data = doc.data()!;
      final items = List<Map<String, dynamic>>.from(
        (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      // 새 item 추가
      items.add({
        'menuId': menuId,
        'quantity': quantity,
        'status': 'ORDERED',
        'completedCount': 0,
        'orderedAt': Timestamp.fromDate(DateTime.now()),
        'priceAtOrder': priceAtOrder,
      });

      // totalPrice 재계산
      int newTotalPrice = 0;
      for (final item in items) {
        final status = (item['status'] as String?)?.toUpperCase() ?? '';
        if (status != 'CANCELED') {
          newTotalPrice += ((item['priceAtOrder'] as int?) ?? 0) *
              ((item['quantity'] as int?) ?? 1);
        }
      }

      await docRef.update({
        'items': items,
        'totalPrice': newTotalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Added item to order: orderId=$orderId, menuId=$menuId, quantity=$quantity',
        name: 'OrderServer',
      );

      return order_model.Order.fromJson({
        ...data,
        'id': orderId,
        'items': items,
        'totalPrice': newTotalPrice,
      });
    } catch (e) {
      developer.log('Error adding menu item: $e', name: 'OrderServer');
      return null;
    }
  }

  /// Order에서 특정 item 제거
  Future<order_model.Order?> removeMenuItem({
    required String orderId,
    required int itemIndex,
  }) async {
    try {
      final docRef = _firestore.collection(_ordersCollection).doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final items = List<Map<String, dynamic>>.from(
        (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      if (itemIndex < 0 || itemIndex >= items.length) return null;

      items.removeAt(itemIndex);

      // totalPrice 재계산
      int newTotalPrice = 0;
      for (final item in items) {
        final status = (item['status'] as String?)?.toUpperCase() ?? '';
        if (status != 'CANCELED') {
          newTotalPrice += ((item['priceAtOrder'] as int?) ?? 0) *
              ((item['quantity'] as int?) ?? 1);
        }
      }

      await docRef.update({
        'items': items,
        'totalPrice': newTotalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Removed item from order: orderId=$orderId, itemIndex=$itemIndex',
        name: 'OrderServer',
      );

      return order_model.Order.fromJson({
        ...data,
        'id': orderId,
        'items': items,
        'totalPrice': newTotalPrice,
      });
    } catch (e) {
      developer.log('Error removing menu item: $e', name: 'OrderServer');
      return null;
    }
  }

  /// Order에서 특정 item 취소 (상태를 canceled로 변경)
  Future<order_model.Order?> cancelMenuItem({
    required String orderId,
    required int itemIndex,
  }) async {
    try {
      final docRef = _firestore.collection(_ordersCollection).doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final items = List<Map<String, dynamic>>.from(
        (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      if (itemIndex < 0 || itemIndex >= items.length) return null;

      items[itemIndex]['status'] = 'CANCELED';

      // totalPrice 재계산
      int newTotalPrice = 0;
      for (final item in items) {
        final status = (item['status'] as String?)?.toUpperCase() ?? '';
        if (status != 'CANCELED') {
          newTotalPrice += ((item['priceAtOrder'] as int?) ?? 0) *
              ((item['quantity'] as int?) ?? 1);
        }
      }

      await docRef.update({
        'items': items,
        'totalPrice': newTotalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Canceled item in order: orderId=$orderId, itemIndex=$itemIndex',
        name: 'OrderServer',
      );

      return order_model.Order.fromJson({
        ...data,
        'id': orderId,
        'items': items,
        'totalPrice': newTotalPrice,
      });
    } catch (e) {
      developer.log('Error canceling menu item: $e', name: 'OrderServer');
      return null;
    }
  }
}

/// OrderServer - 고객 주문 비즈니스 로직
/// Receipts 컬렉션을 관리하며 Orders 정규화 데이터와 연동한다.
class OrderServer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Receipts';
  final _OrdersRepository _ordersRepository = _OrdersRepository();

  /// 새로운 주문 생성 (orderId는 Firestore에서 자동 생성)
  /// 동시에 정규화된 Orders 컬렉션에도 Order 문서 생성
  Future<Order?> createOrder({
    required String storeId,
    required String tableId,
  }) async {
    try {
      final now = DateTime.now();
      final receiptId = _generateReceiptId(now);
      final docRef = _firestore.collection(_collectionName).doc(receiptId);

      // 1) Orders 컬렉션에 먼저 생성 (정규화된 구조) - Order ID 획득
      final order = await _ordersRepository.createOrder(
        receiptId: receiptId,
        storeId: storeId,
        tableId: tableId,
      );

      if (order == null) {
        developer.log('Failed to create order in Orders collection', name: 'OrderServer');
        return null;
      }

      // 2) Receipts 컬렉션에 생성 (orders 배열 포함)
      await docRef.set({
        'orders': [order.id],  // Orders 컬렉션의 Order ID 배열 저장
        'storeId': storeId,
        'tableId': tableId,
        'totalPrice': 0,
        'status': ReceiptStatus.unpaid.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Order(
        id: receiptId,
        storeId: storeId,
        tableId: tableId,
        totalPrice: 0,
        menus: [],
        status: OrderStatus.unpaid,
        createdAt: now,
      );
    } catch (e) {
      developer.log('Error creating order: $e', name: 'OrderServer');
      return null;
    }
  }

  /// 주문 조회 (ID로) - Orders 정규화 구조에서 Menu 정보 포함
  ///
  /// 프로세스:
  /// 1. Receipts에서 기본 주문 정보 조회
  /// 2. Receipts.orderId를 통해 Orders 컬렉션의 Menu 정보 로드
  /// 3. 메뉴 정보 포함된 Order 반환
  Future<Order?> findById(String orderId) async {
    try {
      final DocumentSnapshot snapshot = await _firestore
          .collection(_collectionName)
          .doc(orderId)
          .get();

      if (!snapshot.exists) return null;

      final data = snapshot.data() as Map<String, dynamic>?;
      return await _buildOrderFromReceiptData(snapshot.id, data);
    } catch (e) {
      developer.log('Error fetching order: $e', name: 'OrderServer');
      return null;
    }
  }

  /// 주문 조회 (storeId + tableId로 미정산 주문 찾기) - Orders 정규화 구조에서 Menu 정보 포함
  /// QR 코드 스캔 시 같은 테이블의 기존 주문이 있는지 확인
  ///
  /// 프로세스:
  /// 1. Receipts에서 기존 미정산 주문 조회
  /// 2. Orders 컬렉션의 Menu 정보 배치 로드
  /// 3. 메뉴 정보 포함된 Order 반환
  Future<Order?> findUnpaidOrderByTable({
    required String storeId,
    required String tableId,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('storeId', isEqualTo: storeId)
          .where('tableId', isEqualTo: tableId)
          .where('status', isEqualTo: ReceiptStatus.unpaid.value)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>?;
      return await _buildOrderFromReceiptData(doc.id, data);
    } catch (e) {
      developer.log('Error fetching unpaid order: $e', name: 'OrderServer');
      return null;
    }
  }

  /// 메뉴 추가: 기존 Order에 메뉴 항목 추가
  /// 정규화된 Orders 컬렉션에만 저장 (Receipts.menus[] 제거됨)
  ///
  /// 프로세스:
  /// 1. Receipts에서 orders 배열 조회
  /// 2. 가장 최신 Order (배열의 마지막)에 메뉴 추가
  /// 3. Receipts의 totalPrice 업데이트
  /// 4. UI용 Order 반환
  Future<Order?> addMenu(String receiptId, OrderMenu newMenu) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(receiptId);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();

      if (!snapshot.exists) return null;

      final data = snapshot.data();
      if (data == null) return null;

      // Receipts에서 orders 배열 조회
      final ordersArray = (data['orders'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .where((id) => id.isNotEmpty)
          .toList();

      if (ordersArray.isEmpty) {
        developer.log('No orders found in receipt $receiptId', name: 'OrderServer');
        return null;
      }

      // 가장 최신 Order (배열의 마지막)에 메뉴 추가
      final orderId = ordersArray.last;

      // Orders 컬렉션에 메뉴 추가 (정규화된 구조)
      final addedOrder = await _ordersRepository.addMenuItem(
        orderId: orderId,
        menuId: newMenu.menu.id,
        quantity: newMenu.quantity,
        priceAtOrder: newMenu.menu.price,
      );

      if (addedOrder == null) {
        developer.log('Failed to add menu to order $orderId', name: 'OrderServer');
        return null;
      }

      // Receipts는 최소 정보만 유지 (totalPrice는 Orders에서 계산)
      await docRef.update({
        'totalPrice': addedOrder.totalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        '✅ Receipt updated: receiptId=$receiptId, totalPrice=${addedOrder.totalPrice}',
        name: 'OrderServer',
      );

      return await findById(receiptId);
    } catch (e) {
      developer.log('Error adding menu: $e', name: 'OrderServer');
      return null;
    }
  }

  /// Orders 컬렉션에서 Menu 정보를 조회하여 OrderMenu 객체 생성 (N+1 쿼리 방지)
  ///
  /// 정규화된 Orders 구조에서:
  /// 1. Orders 컬렉션의 items[]에서 menuId 추출
  /// 2. Menus 컬렉션에서 배치 조회
  /// 3. OrderMenu 객체 생성
  Future<List<OrderMenu>> _loadMenusFromOrders(String orderId) async {
    try {
      final orderDoc = await _firestore
          .collection('Orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        developer.log('Order $orderId not found', name: 'OrderServer');
        return [];
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final items = orderData['items'] as List<dynamic>? ?? [];

      if (items.isEmpty) {
        return [];
      }

      // 1. menuId 추출
      final menuIds = <String>[];
      final itemDataMap = <String, Map<String, dynamic>>{};

      for (int i = 0; i < items.length; i++) {
        final item = items[i] as Map<String, dynamic>;
        final menuId = item['menuId'] as String?;

        if (menuId != null && menuId.isNotEmpty) {
          menuIds.add(menuId);
          itemDataMap[menuId] = item;
        }
      }

      if (menuIds.isEmpty) {
        return [];
      }

      // 2. Menus 배치 조회 (N+1 쿼리 방지, 최대 10개씩 청킹)
      final menus = <String, Menu>{};
      for (int i = 0; i < menuIds.length; i += 10) {
        final chunk = menuIds.sublist(i, i + 10 > menuIds.length ? menuIds.length : i + 10);

        final snapshot = await _firestore
            .collection('Menus')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          try {
            final menu = Menu.fromJson({
              ...doc.data(),
              'id': doc.id,
            });
            menus[doc.id] = menu;
          } catch (e) {
            developer.log(
              'Error parsing menu ${doc.id}: $e',
              name: 'OrderServer',
            );
          }
        }
      }

      // 3. OrderMenu 객체 생성
      final orderMenus = <OrderMenu>[];
      for (final menuId in menuIds) {
        final itemData = itemDataMap[menuId]!;
        final menu = menus[menuId];

        if (menu == null) {
          developer.log(
            'Menu $menuId not found in Menus collection',
            name: 'OrderServer',
          );
          continue;
        }

        // orderedAt 파싱
        DateTime? orderedAt;
        final orderedAtValue = itemData['orderedAt'];
        if (orderedAtValue is Timestamp) {
          orderedAt = orderedAtValue.toDate();
        }

        final status = _parseOrderMenuStatus(itemData['status'] as String? ?? 'ordered');

        final orderMenu = OrderMenu(
          id: menuId,  // menuId를 OrderMenu.id로 사용
          status: status,
          quantity: itemData['quantity'] as int? ?? 0,
          completedCount: itemData['completedCount'] as int? ?? 0,
          menu: menu,
          orderedAt: orderedAt,
        );

        orderMenus.add(orderMenu);
      }

      return orderMenus;
    } catch (e) {
      developer.log(
        'Error loading menus from Orders: $e',
        name: 'OrderServer',
      );
      return [];
    }
  }

  /// 메뉴 취소: 상태를 canceled로 변경
  /// 정규화된 Orders 컬렉션에만 반영 (Receipts.menus[] 제거됨)
  ///
  /// 주의: menuId는 OrderMenu의 ID (Firestore에서 생성한 고유 ID)
  /// 이는 Menus 컬렉션의 ID와는 다름
  Future<Order?> cancelMenu(String receiptId, String menuId) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(receiptId);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();

      if (!snapshot.exists) return null;

      final data = snapshot.data();
      if (data == null) return null;

      // Receipts에서 orderId 조회
      final orderId = data['orderId'] as String?;
      if (orderId == null) {
        developer.log('orderId not found in receipt $receiptId', name: 'OrderServer');
        return null;
      }

      // Orders 컬렉션에서 해당 menuId의 인덱스 찾기
      final orderDoc = await _firestore
          .collection('Orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        developer.log('Order $orderId not found', name: 'OrderServer');
        return null;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final items = orderData['items'] as List<dynamic>? ?? [];

      // menuId가 일치하는 항목 찾기 (주의: menuId는 OrderMenu의 ID, 메뉴 ID 아님)
      // 현재 구조에서는 menuId를 직접 비교할 수 없음
      // 대신 클라이언트에서 제공한 menuId로 Orders에서 항목 찾기
      int itemIndex = -1;
      for (int i = 0; i < items.length; i++) {
        final item = items[i] as Map<String, dynamic>;
        // menuId (주문 항목 ID가 아님)로 비교할 경우 추가 정보 필요
        // 현재는 간단히 menuId를 검색
        if (item['id'] == menuId) {
          itemIndex = i;
          break;
        }
      }

      if (itemIndex == -1) {
        developer.log('Menu item $menuId not found in order $orderId', name: 'OrderServer');
        return null;
      }

      // Orders 컬렉션에서 메뉴 취소
      final canceledOrder = await _ordersRepository.cancelMenuItem(
        orderId: orderId,
        itemIndex: itemIndex,
      );

      if (canceledOrder == null) {
        developer.log('Failed to cancel menu in order $orderId', name: 'OrderServer');
        return null;
      }

      // Receipts는 최소 정보만 유지
      await docRef.update({
        'totalPrice': canceledOrder.totalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return await findById(receiptId);
    } catch (e) {
      developer.log('Error canceling menu: $e', name: 'OrderServer');
      return null;
    }
  }

  /// OrderMenuStatus 문자열을 enum으로 변환
  OrderMenuStatus _parseOrderMenuStatus(String statusStr) {
    final normalized = statusStr.toLowerCase();
    if (normalized.contains('cooking')) return OrderMenuStatus.cooking;
    if (normalized.contains('completed')) return OrderMenuStatus.completed;
    if (normalized.contains('canceled')) return OrderMenuStatus.canceled;
    return OrderMenuStatus.ordered;
  }

  /// Order 생성 (기존 Receipt에 새로운 Order 추가)
  /// 새로 생성된 Order와 storeId/tableId를 사용하여 Order 생성
  /// 첫 주문이든 추가 주문이든 항상 호출됨
  Future<Order?> createOrderForReceipt({
    required String receiptId,
    required String storeId,
    required String tableId,
  }) async {
    try {
      final receiptRef = _firestore.collection(_collectionName).doc(receiptId);
      final receiptDoc = await receiptRef.get();
      if (!receiptDoc.exists) return null;

      final data = receiptDoc.data();
      if (data == null) return null;

      final status = data['status'] as String? ?? 'unpaid';
      if (status != 'unpaid') {
        developer.log('Receipt $receiptId is not unpaid. Cannot create additional order.', name: 'OrderServer');
        return null;
      }

      final newOrder = await _ordersRepository.createOrder(
        receiptId: receiptId,
        storeId: storeId,
        tableId: tableId,
      );

      if (newOrder == null) return null;

      final existingOrders = <String>{
        ...(data['orders'] as List<dynamic>? ?? []).map((e) => e.toString()),
      };
      existingOrders.add(newOrder.id);

      await receiptRef.update({
        'orders': existingOrders.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Created additional order for receipt: receiptId=$receiptId, orderId=${newOrder.id}',
        name: 'OrderServer',
      );

      // UI용 Order 반환
      return Order(
        id: receiptId,
        storeId: storeId,
        tableId: tableId,
        totalPrice: 0,
        menus: const [],
        status: OrderStatus.unpaid,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error creating additional order for receipt $receiptId: $e', name: 'OrderServer');
      return null;
    }
  }

  Future<bool> createAdditionalOrder(String receiptId) async {
    try {
      final receiptRef = _firestore.collection(_collectionName).doc(receiptId);
      final receiptDoc = await receiptRef.get();
      if (!receiptDoc.exists) return false;

      final data = receiptDoc.data();
      if (data == null) return false;

      final status = data['status'] as String? ?? 'unpaid';
      if (status != 'unpaid') {
        developer.log('Receipt $receiptId is not unpaid. Cannot create additional order.', name: 'OrderServer');
        return false;
      }

      final storeId = data['storeId'] as String?;
      final tableId = data['tableId'] as String?;
      if (storeId == null || tableId == null) return false;

      final newOrder = await _ordersRepository.createOrder(
        receiptId: receiptId,
        storeId: storeId,
        tableId: tableId,
      );

      if (newOrder == null) return false;

      final existingOrders = <String>{
        ...(data['orders'] as List<dynamic>? ?? []).map((e) => e.toString()),
      };
      existingOrders.add(newOrder.id);

      await receiptRef.update({
        'orders': existingOrders.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      developer.log('Error creating additional order for receipt $receiptId: $e', name: 'OrderServer');
      return false;
    }
  }

  Future<Order?> _buildOrderFromReceiptData(String receiptId, Map<String, dynamic>? data) async {
    if (data == null) return null;

    final statusStr = data['status'] as String? ?? 'unpaid';
    final status = statusStr == 'paid' ? OrderStatus.paid : OrderStatus.unpaid;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final totalPrice = (data['totalPrice'] as num?)?.toInt() ?? 0;

    final aggregatedMenus = <OrderMenu>[];
    final ordersArray = (data['orders'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .where((id) => id.isNotEmpty)
        .toList();

    if (ordersArray.isNotEmpty) {
      for (final id in ordersArray) {
        final menus = await _loadMenusFromOrders(id);
        aggregatedMenus.addAll(menus);
      }
    }

    return Order(
      id: receiptId,
      storeId: data['storeId'] as String? ?? '',
      tableId: data['tableId'] as String? ?? '',
      totalPrice: totalPrice,
      menus: aggregatedMenus,
      status: status,
      createdAt: createdAt,
    );
  }

  String _generateReceiptId(DateTime now) {
    final local = now.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final millis = local.millisecond.toString().padLeft(3, '0');
    return '${local.year}${two(local.month)}${two(local.day)}'
        '${two(local.hour)}${two(local.minute)}${two(local.second)}$millis';
  }
}
