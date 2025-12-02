import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/models/admin/table_order_info.dart';
import 'package:table_order/models/admin/order.dart' as order_model;
import 'package:table_order/server/admin_server/receipt_repository.dart';

/// 주문(Order) 도메인 Repository
///
/// 역할:
/// 1. Receipts 컬렉션: 현재 구조 (비정규화)
/// 2. Orders 컬렉션: 새로운 정규화된 구조 (MenuMigration 이후)
///
/// 전환 기간:
/// - Receipts는 OrderMenu (embedded Menu)를 사용
/// - Orders는 OrderItem (menuId 참조)를 사용
/// - 점진적으로 Orders로 마이그레이션
///
/// 참고: Receipt 관련 메서드는 ReceiptRepository로 이동되었습니다.
class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReceiptRepository _receiptRepository = ReceiptRepository();

  static const String _receiptsCollection = 'Receipts';
  static const String _ordersCollection = 'Orders';

  // ============= Backward Compatibility - Receipt 메서드는 ReceiptRepository로 위임 =============

  /// [Deprecated] ReceiptRepository.fetchUnpaidReceiptsByStore()를 사용하세요
  Future<List<TableOrderInfo>> fetchUnpaidReceiptsByStore(String storeId) async {
    developer.log(
      'OrderRepository.fetchUnpaidReceiptsByStore() is deprecated. Use ReceiptRepository instead.',
      name: 'OrderRepository',
    );
    return await _receiptRepository.fetchUnpaidReceiptsByStore(storeId);
  }

  /// [Deprecated] ReceiptRepository.updateReceiptStatus()를 사용하세요
  Future<bool> updateReceiptStatus({
    required String receiptId,
    required String newStatus,
  }) async {
    developer.log(
      'OrderRepository.updateReceiptStatus() is deprecated. Use ReceiptRepository instead.',
      name: 'OrderRepository',
    );
    return await _receiptRepository.updateReceiptStatus(
      receiptId: receiptId,
      newStatus: newStatus,
    );
  }

  // ============= Orders(주문 항목) 관련 메서드 =============

  /// 주문의 메뉴 상태 업데이트
  Future<bool> updateMenuStatus({
    required String orderId,
    required int menuIndex,
    required String newStatus,
  }) async {
    try {
      final docRef = _firestore.collection(_receiptsCollection).doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) {
        developer.log('Receipt $orderId not found', name: 'OrderRepository');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final menus = List<Map<String, dynamic>>.from(
        (data['menus'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      if (menuIndex < 0 || menuIndex >= menus.length) {
        return false;
      }

      menus[menuIndex]['status'] = newStatus;

      await docRef.update({
        'menus': menus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Updated menu status in receipt: receiptId=$orderId, menuIndex=$menuIndex, newStatus=$newStatus',
        name: 'OrderRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error updating menu status: $e', name: 'OrderRepository');
      return false;
    }
  }

  /// 주문의 메뉴 수량 업데이트
  Future<bool> updateMenuQuantity({
    required String orderId,
    required int menuIndex,
    required int newQuantity,
  }) async {
    try {
      if (newQuantity < 1) return false;

      final docRef = _firestore.collection(_receiptsCollection).doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final menus = List<Map<String, dynamic>>.from(
        (data['menus'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      if (menuIndex < 0 || menuIndex >= menus.length) return false;

      menus[menuIndex]['quantity'] = newQuantity;

      await docRef.update({
        'menus': menus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Updated menu quantity in receipt: receiptId=$orderId, newQuantity=$newQuantity',
        name: 'OrderRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error updating menu quantity: $e', name: 'OrderRepository');
      return false;
    }
  }

  /// 주문의 메뉴 제거
  Future<bool> removeMenu({
    required String orderId,
    required int menuIndex,
  }) async {
    try {
      final docRef = _firestore.collection(_receiptsCollection).doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final menus = List<Map<String, dynamic>>.from(
        (data['menus'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      if (menuIndex < 0 || menuIndex >= menus.length) return false;

      menus.removeAt(menuIndex);

      await docRef.update({
        'menus': menus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Removed menu: orderId=$orderId, menuIndex=$menuIndex',
        name: 'OrderRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error removing menu: $e', name: 'OrderRepository');
      return false;
    }
  }

  // ============= Normalized Orders Collection 관련 메서드 =============
  // (MenuMigration을 통해 생성되는 정규화된 Orders 컬렉션)

  /// Receipt에 속한 모든 Order 조회
  /// Receipt은 여러 Order를 포함할 수 있음
  Future<List<order_model.Order>> getOrdersByReceiptId(String receiptId) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('receiptId', isEqualTo: receiptId)
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
            name: 'OrderRepository',
          );
        }
      }

      developer.log(
        'Fetched ${orders.length} orders for receiptId=$receiptId',
        name: 'OrderRepository',
      );

      return orders;
    } catch (e) {
      developer.log('Error fetching orders by receiptId: $e', name: 'OrderRepository');
      return [];
    }
  }

  /// 특정 테이블의 모든 unpaid Order 조회
  Future<List<order_model.Order>> getUnpaidOrdersByTable(String storeId, String tableId) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('storeId', isEqualTo: storeId)
          .where('tableId', isEqualTo: tableId)
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
            name: 'OrderRepository',
          );
        }
      }

      developer.log(
        'Fetched ${orders.length} orders for table $tableId in store $storeId',
        name: 'OrderRepository',
      );

      return orders;
    } catch (e) {
      developer.log('Error fetching orders by table: $e', name: 'OrderRepository');
      return [];
    }
  }

  /// Order의 특정 item 상태 업데이트 (정규화된 Orders 컬렉션)
  Future<bool> updateOrderItemStatus({
    required String orderId,
    required int itemIndex,
    required String newStatus,
  }) async {
    try {
      final docRef = _firestore.collection(_ordersCollection).doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) {
        developer.log('Order $orderId not found', name: 'OrderRepository');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(
        (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      if (itemIndex < 0 || itemIndex >= items.length) {
        return false;
      }

      items[itemIndex]['status'] = newStatus;

      await docRef.update({
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Updated order item status: orderId=$orderId, itemIndex=$itemIndex, newStatus=$newStatus',
        name: 'OrderRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error updating order item status: $e', name: 'OrderRepository');
      return false;
    }
  }

  /// Order의 특정 item 수량 업데이트 (정규화된 Orders 컬렉션)
  Future<bool> updateOrderItemQuantity({
    required String orderId,
    required int itemIndex,
    required int newQuantity,
  }) async {
    try {
      if (newQuantity < 1) return false;

      final docRef = _firestore.collection(_ordersCollection).doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(
        (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      if (itemIndex < 0 || itemIndex >= items.length) return false;

      items[itemIndex]['quantity'] = newQuantity;

      await docRef.update({
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Updated order item quantity: orderId=$orderId, itemIndex=$itemIndex, newQuantity=$newQuantity',
        name: 'OrderRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error updating order item quantity: $e', name: 'OrderRepository');
      return false;
    }
  }

  /// Order에서 특정 item 제거 (정규화된 Orders 컬렉션)
  Future<bool> removeOrderItem({
    required String orderId,
    required int itemIndex,
  }) async {
    try {
      final docRef = _firestore.collection(_ordersCollection).doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(
        (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      if (itemIndex < 0 || itemIndex >= items.length) return false;

      items.removeAt(itemIndex);

      await docRef.update({
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Removed order item: orderId=$orderId, itemIndex=$itemIndex',
        name: 'OrderRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error removing order item: $e', name: 'OrderRepository');
      return false;
    }
  }

  /// Order에 새로운 item 추가 (정규화된 Orders 컬렉션)
  Future<bool> addOrderItem({
    required String orderId,
    required String menuId,
    required int quantity,
    required int priceAtOrder,
  }) async {
    try {
      final docRef = _firestore.collection(_ordersCollection).doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(
        (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      // 새로운 item 추가
      items.add({
        'menuId': menuId,
        'quantity': quantity,
        'status': 'ordered',
        'completedCount': 0,
        'orderedAt': DateTime.now().toIso8601String(),
        'priceAtOrder': priceAtOrder,
      });

      // totalPrice 재계산
      int newTotalPrice = 0;
      for (final item in items) {
        if (item['status'] != 'canceled') {
          newTotalPrice += ((item['priceAtOrder'] as int?) ?? 0) * ((item['quantity'] as int?) ?? 1);
        }
      }

      await docRef.update({
        'items': items,
        'totalPrice': newTotalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Added item to order: orderId=$orderId, menuId=$menuId, quantity=$quantity',
        name: 'OrderRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error adding order item: $e', name: 'OrderRepository');
      return false;
    }
  }

}
