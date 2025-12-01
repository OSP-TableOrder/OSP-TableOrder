import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/models/customer/order.dart';
import 'package:table_order/models/customer/order_menu.dart';
import 'package:table_order/models/common/order_menu_status.dart';
import 'package:table_order/models/customer/order_status.dart';

class OrderServerStub {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Orders';

  /// 새로운 주문 생성 (orderId는 Firestore에서 자동 생성)
  Future<Order?> createOrder({
    required String storeId,
    required String tableId,
  }) async {
    try {
      final now = DateTime.now();
      final receiptId = _generateReceiptId(now);
      final docRef = _firestore.collection(_collectionName).doc(receiptId);

      await docRef.set({
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
  /// OrderMenu의 ID는 Firestore에서 자동 생성됨
  Future<Order?> addMenu(String orderId, OrderMenu newMenu) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(orderId);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();

      if (!snapshot.exists) return null;

      final data = snapshot.data();
      final order = _parseOrder(orderId, data);
      if (order == null) return null;

      // Firestore 자동 생성 ID 획득 (문서를 실제로 생성하지는 않음)
      final menuId = _firestore.collection(_collectionName).doc().id;

      // 새로운 OrderMenu를 Firestore가 생성한 ID와 함께 생성
      final menuWithId = OrderMenu(
        id: menuId,
        status: newMenu.status,
        quantity: newMenu.quantity,
        completedCount: newMenu.completedCount,
        menu: newMenu.menu,
      );

      // 기존 메뉴들
      final updatedMenus = List<OrderMenu>.from(order.menus);
      updatedMenus.add(menuWithId);

      // 총 금액 재계산
      final newTotalPrice = updatedMenus
          .where((m) => m.status.toString() != 'OrderMenuStatus.canceled')
          .fold<int>(0, (acc, m) => acc + (m.menu.price * m.quantity));

      // Firestore 업데이트
      await docRef.update({
        'menus': updatedMenus.map((m) => _menuToMap(m)).toList(),
        'totalPrice': newTotalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Order(
        id: orderId,
        storeId: order.storeId,
        tableId: order.tableId,
        totalPrice: newTotalPrice,
        menus: updatedMenus,
        createdAt: order.createdAt,
      );
    } catch (e) {
      developer.log('Error adding menu: $e', name: 'OrderServerStub');
      return null;
    }
  }

  /// 메뉴 취소: 상태를 canceled로 변경
  Future<Order?> cancelMenu(String orderId, String menuId) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(orderId);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();

      if (!snapshot.exists) return null;

      final data = snapshot.data();
      final order = _parseOrder(orderId, data);
      if (order == null) return null;

      final menuIndex = order.menus.indexWhere((m) => m.id == menuId);
      if (menuIndex == -1) return order;

      final target = order.menus[menuIndex];
      if (!target.isCancelable) return order;

      // 메뉴 상태 변경
      final updatedMenus = List<OrderMenu>.from(order.menus);
      updatedMenus[menuIndex] = target.copyWith(status: OrderMenuStatus.canceled);

      // 총 금액 재계산
      final newTotalPrice = updatedMenus
          .where((m) => m.status.toString() != 'OrderMenuStatus.canceled')
          .fold<int>(0, (acc, m) => acc + (m.menu.price * m.quantity));

      // Firestore 업데이트
      await docRef.update({
        'menus': updatedMenus.map((m) => _menuToMap(m)).toList(),
        'totalPrice': newTotalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Order(
        id: orderId,
        storeId: order.storeId,
        tableId: order.tableId,
        totalPrice: newTotalPrice,
        menus: updatedMenus,
        createdAt: order.createdAt,
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

        final orderMenu = OrderMenu(
          id: m['id'] as String? ?? '',
          status: status,
          quantity: m['quantity'] as int? ?? 0,
          completedCount: m['completedCount'] as int? ?? 0,
          menu: menu,
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

  /// OrderMenu를 Map으로 변환
  Map<String, dynamic> _menuToMap(OrderMenu menu) {
    return {
      'id': menu.id,
      'status': menu.status.toString(),
      'quantity': menu.quantity,
      'completedCount': menu.completedCount,
      'menu': {
        'id': menu.menu.id,
        'storeId': menu.menu.storeId,
        'categoryId': menu.menu.categoryId,
        'name': menu.menu.name,
        'description': menu.menu.description,
        'imageUrl': menu.menu.imageUrl,
        'price': menu.menu.price,
        'isSoldOut': menu.menu.isSoldOut,
        'isRecommended': menu.menu.isRecommended,
      },
    };
  }

  String _generateReceiptId(DateTime now) {
    final local = now.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final millis = local.millisecond.toString().padLeft(3, '0');
    return '${local.year}${two(local.month)}${two(local.day)}'
        '${two(local.hour)}${two(local.minute)}${two(local.second)}$millis';
  }
}
