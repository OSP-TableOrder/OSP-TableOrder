import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/models/admin/order.dart' as order_model;
import 'package:table_order/models/customer/order.dart';
import 'package:table_order/models/customer/order_menu.dart';
import 'package:table_order/models/common/order_menu_status.dart';
import 'package:table_order/models/customer/order_status.dart';

/// OrderServer - 정규화된 Orders 컬렉션 관리
///
/// 역할:
/// - 새로운 정규화된 데이터 구조 지원 (Orders 컬렉션)
/// - menuId 참조 기반 데이터 저장
/// - OrderServerStub과 병행하여 마이그레이션 기간 지원
///
/// 참고: 기존 Receipts 컬렉션은 OrderServerStub이 담당
class OrderServer {
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
        'status': 'ordered',
        'completedCount': 0,
        'orderedAt': Timestamp.fromDate(DateTime.now()),
        'priceAtOrder': priceAtOrder,
      });

      // totalPrice 재계산
      int newTotalPrice = 0;
      for (final item in items) {
        if (item['status'] != 'canceled') {
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
        if (item['status'] != 'canceled') {
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

      items[itemIndex]['status'] = 'canceled';

      // totalPrice 재계산
      int newTotalPrice = 0;
      for (final item in items) {
        if (item['status'] != 'canceled') {
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

// ====================================================================================
// OrderServerStub - 기존 비정규화된 Receipts 컬렉션 관리 (backward compatibility)
// ====================================================================================

class OrderServerStub {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Receipts';

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
      final orderServer = OrderServer();
      final order = await orderServer.createOrder(
        receiptId: receiptId,
        storeId: storeId,
        tableId: tableId,
      );

      // 2) Receipts 컬렉션에 생성 (orderId 필드 포함)
      await docRef.set({
        'orderId': order?.id,  // Orders 컬렉션의 Order ID 저장
        'storeId': storeId,
        'tableId': tableId,
        'totalPrice': 0,
        'menus': [],
        'status': 'unpaid',
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
      developer.log('Error creating order: $e', name: 'OrderServerStub');
      return null;
    }
  }

  /// 주문 조회 (ID로)
  Future<Order?> findById(String orderId) async {
    try {
      final DocumentSnapshot snapshot = await _firestore
          .collection(_collectionName)
          .doc(orderId)
          .get();

      if (!snapshot.exists) return null;

      final data = snapshot.data() as Map<String, dynamic>?;
      return _parseOrder(snapshot.id, data);
    } catch (e) {
      developer.log('Error fetching order: $e', name: 'OrderServerStub');
      return null;
    }
  }

  /// 주문 조회 (storeId + tableId로 미정산 주문 찾기)
  /// QR 코드 스캔 시 같은 테이블의 기존 주문이 있는지 확인
  Future<Order?> findUnpaidOrderByTable({
    required String storeId,
    required String tableId,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('storeId', isEqualTo: storeId)
          .where('tableId', isEqualTo: tableId)
          .where('status', isEqualTo: 'unpaid')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>?;
      return _parseOrder(doc.id, data);
    } catch (e) {
      developer.log('Error fetching unpaid order: $e', name: 'OrderServerStub');
      return null;
    }
  }

  /// 메뉴 추가: 새로운 OrderMenu 항목 추가
  /// 정규화된 Orders 컬렉션에만 저장 (Receipts.menus[] 제거됨)
  ///
  /// 프로세스:
  /// 1. Receipts에서 orderId 조회
  /// 2. OrderServer.addMenuItem()으로 Orders에 항목 추가
  /// 3. UI용 Order 반환 (메뉴 정보는 UI에서 별도 조회)
  Future<Order?> addMenu(String receiptId, OrderMenu newMenu) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(receiptId);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();

      if (!snapshot.exists) return null;

      final data = snapshot.data();
      if (data == null) return null;

      // Receipts에서 orderId 조회
      final orderId = data['orderId'] as String?;
      if (orderId == null) {
        developer.log('orderId not found in receipt $receiptId', name: 'OrderServerStub');
        return null;
      }

      // Orders 컬렉션에 메뉴 추가 (정규화된 구조)
      final orderServer = OrderServer();
      final addedOrder = await orderServer.addMenuItem(
        orderId: orderId,
        menuId: newMenu.menu.id,
        quantity: newMenu.quantity,
        priceAtOrder: newMenu.menu.price,
      );

      if (addedOrder == null) {
        developer.log('Failed to add menu to order $orderId', name: 'OrderServerStub');
        return null;
      }

      // Receipts는 최소 정보만 유지 (totalPrice는 Orders에서 계산)
      await docRef.update({
        'totalPrice': addedOrder.totalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // UI용 Order 반환
      // 메뉴 정보는 UI에서 Orders 데이터로부터 별도 조회
      return Order(
        id: receiptId,
        storeId: addedOrder.storeId,
        tableId: addedOrder.tableId,
        totalPrice: addedOrder.totalPrice,
        menus: [],  // 비정규화된 메뉴는 사용 안 함
        status: OrderStatus.unpaid,
        createdAt: addedOrder.createdAt,
      );
    } catch (e) {
      developer.log('Error adding menu: $e', name: 'OrderServerStub');
      return null;
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
        developer.log('orderId not found in receipt $receiptId', name: 'OrderServerStub');
        return null;
      }

      // Orders 컬렉션에서 해당 menuId의 인덱스 찾기
      final orderDoc = await _firestore
          .collection('Orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        developer.log('Order $orderId not found', name: 'OrderServerStub');
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
        developer.log('Menu item $menuId not found in order $orderId', name: 'OrderServerStub');
        return null;
      }

      // Orders 컬렉션에서 메뉴 취소
      final orderServer = OrderServer();
      final canceledOrder = await orderServer.cancelMenuItem(
        orderId: orderId,
        itemIndex: itemIndex,
      );

      if (canceledOrder == null) {
        developer.log('Failed to cancel menu in order $orderId', name: 'OrderServerStub');
        return null;
      }

      // Receipts는 최소 정보만 유지
      await docRef.update({
        'totalPrice': canceledOrder.totalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // UI용 Order 반환
      return Order(
        id: receiptId,
        storeId: canceledOrder.storeId,
        tableId: canceledOrder.tableId,
        totalPrice: canceledOrder.totalPrice,
        menus: [],  // 비정규화된 메뉴는 사용 안 함
        status: OrderStatus.unpaid,
        createdAt: canceledOrder.createdAt,
      );
    } catch (e) {
      developer.log('Error canceling menu: $e', name: 'OrderServerStub');
      return null;
    }
  }

  /// Order 데이터 파싱
  Order? _parseOrder(String orderId, Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      final menus = <OrderMenu>[];
      final menusData = data['menus'] as List<dynamic>? ?? [];

      for (final menuData in menusData) {
        final m = menuData as Map<String, dynamic>?;
        if (m == null) continue;

        final menuInfo = m['menu'] as Map<String, dynamic>?;
        if (menuInfo == null) continue;

        // Menu 파싱
        final price = menuInfo['price'];
        final priceInt = price is int ? price : (int.tryParse(price as String? ?? '0') ?? 0);

        final menu = Menu(
          id: menuInfo['id'] as String? ?? '',
          storeId: menuInfo['storeId'] as String? ?? '',
          categoryId: menuInfo['categoryId'],
          name: menuInfo['name'] as String? ?? '',
          description: menuInfo['description'] as String? ?? '',
          imageUrl: menuInfo['imageUrl'],
          price: priceInt,
          isSoldOut: menuInfo['isSoldOut'] as bool? ?? false,
          isRecommended: menuInfo['isRecommended'] as bool? ?? false,
        );

        // OrderMenuStatus 파싱
        final statusStr = m['status'] as String? ?? 'OrderMenuStatus.ordered';
        final status = _parseOrderMenuStatus(statusStr);

        // orderedAt 파싱
        DateTime? orderedAt;
        final orderedAtTimestamp = m['orderedAt'] as Timestamp?;
        if (orderedAtTimestamp != null) {
          orderedAt = orderedAtTimestamp.toDate();
        }

        final orderMenu = OrderMenu(
          id: m['id'] as String? ?? '',
          status: status,
          quantity: m['quantity'] as int? ?? 0,
          completedCount: m['completedCount'] as int? ?? 0,
          menu: menu,
          orderedAt: orderedAt,
        );

        menus.add(orderMenu);
      }

      final statusStr = data['status'] as String? ?? 'unpaid';
      final status = statusStr == 'paid' ? OrderStatus.paid : OrderStatus.unpaid;

      // createdAt 파싱
      DateTime? createdAt;
      final timestamp = data['createdAt'] as Timestamp?;
      if (timestamp != null) {
        createdAt = timestamp.toDate();
      }

      return Order(
        id: orderId,
        storeId: data['storeId'] as String? ?? '',
        tableId: data['tableId'] as String? ?? '',
        totalPrice: (data['totalPrice'] as num?)?.toInt() ?? 0,
        menus: menus,
        status: status,
        createdAt: createdAt,
      );
    } catch (e) {
      developer.log('Error parsing order: $e', name: 'OrderServerStub');
      return null;
    }
  }

  /// OrderMenuStatus 문자열을 enum으로 변환
  OrderMenuStatus _parseOrderMenuStatus(String statusStr) {
    if (statusStr.contains('cooking')) return OrderMenuStatus.cooking;
    if (statusStr.contains('completed')) return OrderMenuStatus.completed;
    if (statusStr.contains('canceled')) return OrderMenuStatus.canceled;
    return OrderMenuStatus.ordered;
  }

  String _generateReceiptId(DateTime now) {
    final local = now.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final millis = local.millisecond.toString().padLeft(3, '0');
    return '${local.year}${two(local.month)}${two(local.day)}'
        '${two(local.hour)}${two(local.minute)}${two(local.second)}$millis';
  }
}
