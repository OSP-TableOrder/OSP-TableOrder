import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/models/admin/table_order_info.dart';

/// 영수증(Receipt) 도메인 Repository
/// Receipts 컬렉션의 CRUD 및 Firestore 데이터 접근을 담당하는 계층
///
/// 구조:
/// - 비정규화: Receipt.menus[] (OrderMenu 직접 포함)
/// - 정규화: Receipt.orders[] (Order ID 참조) - 마이그레이션 이후
class ReceiptRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
          .where('status', isEqualTo: 'unpaid')
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
        final orders = ordersMetadata['items'] as List<dynamic>;

        // TableOrder 생성
        final tableOrder = TableOrder(
          orderId: receiptDoc.id,
          tableId: tableId,
          tableName: tableName,
          items: orders,
          orderTime: _formatTime(data['createdAt'] as Timestamp?),
          totalPrice: (data['totalPrice'] as int?) ?? 0,
          hasNewOrder: orders.any((item) => (item['status'] as String?)?.contains('ordered') ?? false),
          orderStatus: orders.isNotEmpty ? OrderStatus.ordered : OrderStatus.empty,
        );

        // 테이블별 영수증 리스트에 추가
        if (!tableReceiptsMap.containsKey(tableId)) {
          tableReceiptsMap[tableId] = [];
        }
        tableReceiptsMap[tableId]!.add(tableOrder);
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
        'status': 'unpaid',
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

  /// Receipt의 menus 배열에 메뉴 추가
  Future<bool> addMenuToReceipt({
    required String receiptId,
    required Map<String, dynamic> menuData,
  }) async {
    try {
      final docRef = _firestore.collection(_receiptsCollection).doc(receiptId);
      final doc = await docRef.get();

      if (!doc.exists) {
        developer.log('Receipt $receiptId not found', name: 'ReceiptRepository');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final menus = List<Map<String, dynamic>>.from(
        (data['menus'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      // 새 메뉴 항목 추가
      final newMenu = {
        ...menuData,
        'orderedAt': DateTime.now().toIso8601String(),
        'status': menuData['status'] ?? 'ordered',
      };

      menus.add(newMenu);

      // totalPrice 업데이트
      int totalPrice = (data['totalPrice'] as int?) ?? 0;
      final quantity = (menuData['quantity'] as int?) ?? 1;
      final price = (menuData['price'] as int?) ?? 0;
      totalPrice += (price * quantity);

      await docRef.update({
        'menus': menus,
        'totalPrice': totalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Added menu to receipt: receiptId=$receiptId, menuName=${menuData['name']}',
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
  Future<Map<String, dynamic>> _fetchOrdersByReceiptWithMetadata(
    String receiptId,
    Map<String, dynamic> receiptData,
  ) async {
    try {
      final items = _extractMenusFromReceipt(receiptData);
      return {'items': items, 'receiptId': receiptId};
    } catch (e) {
      developer.log(
        'Error extracting menus from receipt $receiptId: $e',
        name: 'ReceiptRepository',
      );
      return {'items': <dynamic>[], 'receiptId': receiptId};
    }
  }

  /// Receipt 문서에서 메뉴 항목을 추출하여 표시용 형식으로 변환
  /// 메뉴는 Receipt.menus 배열에 직접 포함되어 있음
  List<dynamic> _extractMenusFromReceipt(Map<String, dynamic> receiptData) {
    final menus = receiptData['menus'] as List<dynamic>? ?? [];
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

  /// 시간 포맷팅
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '-';

    final dateTime = timestamp.toDate();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
