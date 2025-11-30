import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/models/admin/table_order_info.dart';

class TableOrderServer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 특정 가게의 모든 미정산 주문 조회 (테이블별 그룹화, 각 테이블의 여러 주문 지원)
  Future<List<TableOrderInfo>> fetchUnpaidOrdersByStore(String storeId) async {
    try {
      developer.log(
        'Fetching unpaid orders for storeId=$storeId',
        name: 'TableOrderServer',
      );

      // Orders 컬렉션에서 status가 'unpaid'이고 storeId인 주문 조회
      // (필드 순서: status → storeId → createdAt 순서로 인덱스 구성)
      final ordersSnapshot = await _firestore
          .collection('Orders')
          .where('status', isEqualTo: 'unpaid')
          .where('storeId', isEqualTo: storeId)
          .orderBy('createdAt', descending: true)
          .get();

      // Tables 컬렉션에서 테이블 목록 조회
      final tablesSnapshot = await _firestore
          .collection('Tables')
          .where('storeId', isEqualTo: storeId)
          .get();

      final tableMap = <String, String>{}; // tableId -> tableName 매핑
      developer.log(
        'Tables documents found: ${tablesSnapshot.docs.length}',
        name: 'TableOrderServer',
      );

      for (final doc in tablesSnapshot.docs) {
        final data = doc.data();
        tableMap[doc.id] = data['name'] ?? '테이블';
        developer.log(
          'Table: id=${doc.id}, name=${data['name']}',
          name: 'TableOrderServer',
        );
      }

      developer.log(
        'TableMap keys: ${tableMap.keys}',
        name: 'TableOrderServer',
      );

      // 테이블별로 주문들을 그룹화
      final tableOrdersMap = <String, List<TableOrder>>{};

      developer.log(
        'Total unpaid orders found: ${ordersSnapshot.docs.length}',
        name: 'TableOrderServer',
      );

      for (final orderDoc in ordersSnapshot.docs) {
        final data = orderDoc.data();
        developer.log(
          'Processing order: ${orderDoc.id}, data keys: ${data.keys}',
          name: 'TableOrderServer',
        );

        final tableId = data['tableId'] as String?;
        developer.log(
          'Order ${orderDoc.id} - tableId: $tableId',
          name: 'TableOrderServer',
        );

        if (tableId == null) {
          developer.log(
            'Skipping order ${orderDoc.id}: tableId is null',
            name: 'TableOrderServer',
          );
          continue;
        }

        final tableName = tableMap[tableId] ?? tableId;
        developer.log(
          'Order ${orderDoc.id} - tableName: $tableName',
          name: 'TableOrderServer',
        );

        // 이 주문의 메뉴 아이템들 파싱
        final items = <dynamic>[];
        var hasNewOrder = false;
        final menusData = data['menus'] as List<dynamic>? ?? [];

        developer.log(
          'Order ${orderDoc.id} has ${menusData.length} menus',
          name: 'TableOrderServer',
        );

        for (final menuData in menusData) {
          if (menuData is Map<String, dynamic>) {
            final menu = menuData['menu'] as Map<String, dynamic>?;
            final menuStatus = menuData['status'] as String?;
            final quantity = menuData['quantity'] as int? ?? 1;
            final price = menu?['price'] as int? ?? 0;

            if (menu != null) {
              final menuName = menu['name'] as String? ?? '미정의';

              // 상태 파싱: Firestore에는 "OrderMenuStatus.ordered" 형식으로 저장됨
              final parsedStatus = _parseMenuStatus(menuStatus);

              // 메뉴 정보를 Map으로 저장 (이름, 가격, 수량, 상태)
              items.add({
                'name': menuName,
                'price': price,
                'quantity': quantity,
                'status': parsedStatus,
              });

              // '접수 대기' (ordered) 상태의 메뉴가 있으면 신규 주문으로 표시
              if (parsedStatus == 'ORDERED') {
                hasNewOrder = true;
                developer.log(
                  'Menu $menuName has ORDERED status - setting hasNewOrder=true',
                  name: 'TableOrderServer',
                );
              }

              developer.log(
                'Added menu: $menuName (status: $menuStatus, qty: $quantity, price: $price)',
                name: 'TableOrderServer',
              );
            }
          }
        }

        // 주문 시간 계산
        String? orderTime;
        final timestamp = data['createdAt'] as Timestamp?;
        if (timestamp != null) {
          final dateTime = timestamp.toDate();
          orderTime = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        }

        // TableOrder 생성
        final tableOrder = TableOrder(
          orderId: orderDoc.id,
          tableId: tableId,
          tableName: tableName,
          items: items,
          orderTime: orderTime,
          totalPrice: (data['totalPrice'] as int?) ?? 0,
          hasNewOrder: hasNewOrder,
          orderStatus: hasNewOrder ? OrderStatus.ordered : OrderStatus.empty,
        );

        // 테이블별 주문 리스트에 추가
        if (!tableOrdersMap.containsKey(tableId)) {
          tableOrdersMap[tableId] = [];
        }
        tableOrdersMap[tableId]!.add(tableOrder);

        developer.log(
          'Created TableOrder: orderId=${orderDoc.id}, tableName=$tableName, itemCount=${items.length}',
          name: 'TableOrderServer',
        );
      }

      // TableOrderInfo 리스트 생성
      final result = <TableOrderInfo>[];
      for (final entry in tableOrdersMap.entries) {
        final tableId = entry.key;
        final orders = entry.value;

        final tableOrderInfo = TableOrderInfo(
          tableId: tableId,
          tableName: tableMap[tableId] ?? tableId,
          orders: orders,
        );

        result.add(tableOrderInfo);

        developer.log(
          'TableOrderInfo for $tableId: ${orders.length} orders',
          name: 'TableOrderServer',
        );
      }

      developer.log(
        'Fetched ${result.length} tables with unpaid orders',
        name: 'TableOrderServer',
      );

      return result;
    } catch (e) {
      developer.log(
        'Error fetching unpaid orders: $e',
        name: 'TableOrderServer',
      );
      return [];
    }
  }

  /// 주문의 메뉴 상태 업데이트 (개별 메뉴)
  Future<bool> updateMenuStatus({
    required String orderId,
    required int menuIndex,
    required String newStatus,
  }) async {
    try {
      developer.log(
        'Updating menu status for orderId=$orderId, menuIndex=$menuIndex, newStatus=$newStatus',
        name: 'TableOrderServer',
      );

      final docRef = _firestore.collection('Orders').doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) {
        developer.log('Order $orderId not found', name: 'TableOrderServer');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final menus = List<Map<String, dynamic>>.from(
        (data['menus'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      if (menuIndex < 0 || menuIndex >= menus.length) {
        developer.log(
          'Invalid menuIndex=$menuIndex for order $orderId with ${menus.length} menus',
          name: 'TableOrderServer',
        );
        return false;
      }

      // 상태를 정규형식(UPPERCASE)에서 Enum 형식으로 변환하여 저장
      final firestoreStatus = _statusToFirestoreFormat(newStatus);
      menus[menuIndex]['status'] = firestoreStatus;

      await docRef.update({
        'menus': menus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Successfully updated menu status to $firestoreStatus',
        name: 'TableOrderServer',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error updating menu status: $e',
        name: 'TableOrderServer',
      );
      return false;
    }
  }

  /// 주문의 메뉴 수량 업데이트 (개별 메뉴)
  Future<bool> updateMenuQuantity({
    required String orderId,
    required int menuIndex,
    required int newQuantity,
  }) async {
    try {
      developer.log(
        'Updating menu quantity for orderId=$orderId, menuIndex=$menuIndex, newQuantity=$newQuantity',
        name: 'TableOrderServer',
      );

      if (newQuantity < 1) {
        developer.log('Invalid newQuantity=$newQuantity', name: 'TableOrderServer');
        return false;
      }

      final docRef = _firestore.collection('Orders').doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) {
        developer.log('Order $orderId not found', name: 'TableOrderServer');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final menus = List<Map<String, dynamic>>.from(
        (data['menus'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      if (menuIndex < 0 || menuIndex >= menus.length) {
        developer.log(
          'Invalid menuIndex=$menuIndex for order $orderId with ${menus.length} menus',
          name: 'TableOrderServer',
        );
        return false;
      }

      menus[menuIndex]['quantity'] = newQuantity;

      // 총 금액 재계산
      final newTotalPrice = _calculateTotalPrice(menus);

      await docRef.update({
        'menus': menus,
        'totalPrice': newTotalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Successfully updated menu quantity to $newQuantity, new total price: $newTotalPrice',
        name: 'TableOrderServer',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error updating menu quantity: $e',
        name: 'TableOrderServer',
      );
      return false;
    }
  }

  /// 주문의 메뉴 제거 (부분 취소)
  Future<bool> removeMenu({
    required String orderId,
    required int menuIndex,
  }) async {
    try {
      developer.log(
        'Removing menu for orderId=$orderId, menuIndex=$menuIndex',
        name: 'TableOrderServer',
      );

      final docRef = _firestore.collection('Orders').doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) {
        developer.log('Order $orderId not found', name: 'TableOrderServer');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final menus = List<Map<String, dynamic>>.from(
        (data['menus'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      if (menuIndex < 0 || menuIndex >= menus.length) {
        developer.log(
          'Invalid menuIndex=$menuIndex for order $orderId with ${menus.length} menus',
          name: 'TableOrderServer',
        );
        return false;
      }

      menus.removeAt(menuIndex);

      // 총 금액 재계산
      final newTotalPrice = _calculateTotalPrice(menus);

      await docRef.update({
        'menus': menus,
        'totalPrice': newTotalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Successfully removed menu, new total price: $newTotalPrice',
        name: 'TableOrderServer',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error removing menu: $e',
        name: 'TableOrderServer',
      );
      return false;
    }
  }

  /// Firestore의 상태 문자열을 파싱하여 정규화된 상태로 변환
  /// "OrderMenuStatus.ordered" -> "ORDERED"
  /// "OrderMenuStatus.cooking" -> "COOKING"
  /// "OrderMenuStatus.completed" -> "COMPLETED"
  /// "OrderMenuStatus.canceled" -> "CANCELED"
  String _parseMenuStatus(String? statusStr) {
    if (statusStr == null) return 'ORDERED';

    if (statusStr.contains('cooking')) return 'COOKING';
    if (statusStr.contains('completed')) return 'COMPLETED';
    if (statusStr.contains('canceled')) return 'CANCELED';

    return 'ORDERED';
  }

  /// 정규화된 상태(UPPERCASE)를 Firestore 저장 형식으로 변환
  /// "ORDERED" -> "OrderMenuStatus.ordered"
  /// "COOKING" -> "OrderMenuStatus.cooking"
  /// "COMPLETED" -> "OrderMenuStatus.completed"
  /// "CANCELED" -> "OrderMenuStatus.canceled"
  String _statusToFirestoreFormat(String status) {
    return switch (status.toUpperCase()) {
      'COOKING' => 'OrderMenuStatus.cooking',
      'COMPLETED' => 'OrderMenuStatus.completed',
      'CANCELED' => 'OrderMenuStatus.canceled',
      _ => 'OrderMenuStatus.ordered',
    };
  }

  /// 메뉴 목록의 총 금액 계산
  int _calculateTotalPrice(List<Map<String, dynamic>> menus) {
    int total = 0;
    for (final menu in menus) {
      final status = menu['status'] as String? ?? '';
      if (!status.contains('canceled')) {
        final price = menu['menu']?['price'] as int? ?? 0;
        final quantity = menu['quantity'] as int? ?? 1;
        total += price * quantity;
      }
    }
    return total;
  }

  /// 주문 상태 변경 (unpaid -> paid)
  Future<bool> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    try {
      developer.log(
        'Updating order status for orderId=$orderId, newStatus=$newStatus',
        name: 'TableOrderServer',
      );

      final docRef = _firestore.collection('Orders').doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) {
        developer.log('Order $orderId not found', name: 'TableOrderServer');
        return false;
      }

      await docRef.update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Successfully updated order status to $newStatus',
        name: 'TableOrderServer',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error updating order status: $e',
        name: 'TableOrderServer',
      );
      return false;
    }
  }

  /// 주문에 메뉴 추가
  Future<bool> addMenuToOrder({
    required String orderId,
    String? menuName,
    int? price,
    Map<String, dynamic>? menu,
    required int quantity,
  }) async {
    try {
      developer.log(
        'Adding menu to order: orderId=$orderId, menuName=$menuName, price=$price, menu=$menu, quantity=$quantity',
        name: 'TableOrderServer',
      );

      final docRef = _firestore.collection('Orders').doc(orderId);
      final doc = await docRef.get();

      if (!doc.exists) {
        developer.log('Order $orderId not found', name: 'TableOrderServer');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final menus = List<Map<String, dynamic>>.from(
        (data['menus'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );

      // 메뉴 객체 생성 (전체 메뉴 객체가 있으면 그걸 사용, 없으면 기본 정보만 사용)
      final newMenuItem = {
        'menu': menu ?? {
          'name': menuName,
          'price': price,
        },
        'quantity': quantity,
        'status': 'OrderMenuStatus.ordered',
      };

      menus.add(newMenuItem);

      // 총 금액 재계산
      final newTotalPrice = _calculateTotalPrice(menus);

      await docRef.update({
        'menus': menus,
        'totalPrice': newTotalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Successfully added menu to order, new total price: $newTotalPrice',
        name: 'TableOrderServer',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error adding menu to order: $e',
        name: 'TableOrderServer',
      );
      return false;
    }
  }
}
