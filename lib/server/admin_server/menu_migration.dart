import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore 데이터 정규화 마이그레이션
/// 현재 Receipts.menus[].menu에 포함된 메뉴 정보를 Menus 컬렉션으로 추출
class MenuMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Phase 1: Menus 컬렉션 생성 (기존 Receipts에서 메뉴 정보 추출)
  Future<int> createMenusCollection() async {
    try {
      developer.log('Starting Menus collection creation...', name: 'MenuMigration');

      final receipts = await _firestore.collection('Receipts').get();
      final menusMap = <String, Map<String, dynamic>>{};

      // 모든 Receipts에서 메뉴 정보 추출 (중복 제거)
      for (final doc in receipts.docs) {
        final data = doc.data();
        final menus = data['menus'] as List<dynamic>? ?? [];

        for (final item in menus) {
          if (item is Map<String, dynamic>) {
            final menu = item['menu'] as Map<String, dynamic>?;
            if (menu != null && menu['id'] != null) {
              menusMap[menu['id'] as String] = menu;
            }
          }
        }
      }

      // Menus 컬렉션에 저장
      int count = 0;
      for (final entry in menusMap.entries) {
        final menuId = entry.key;
        final menuData = entry.value;

        await _firestore.collection('Menus').doc(menuId).set({
          'id': menuId,
          'storeId': menuData['storeId'] as String? ?? '',
          'categoryId': menuData['categoryId'] as String? ?? '',
          'name': menuData['name'] as String? ?? '미정의',
          'description': menuData['description'] as String? ?? '',
          'imageUrl': menuData['imageUrl'],
          'price': (menuData['price'] as num?)?.toInt() ?? 0,
          'isSoldOut': menuData['isSoldOut'] as bool? ?? false,
          'isActive': true,
          'stock': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        count++;
      }

      developer.log('Created $count menu documents', name: 'MenuMigration');
      return count;
    } catch (e) {
      developer.log('Error creating Menus collection: $e', name: 'MenuMigration');
      rethrow;
    }
  }

  /// Phase 2: Orders 컬렉션 생성 (각 Receipt의 메뉴마다 Order 문서 생성)
  Future<int> createOrdersCollection() async {
    try {
      developer.log('Starting Orders collection creation...', name: 'MenuMigration');

      final receipts = await _firestore.collection('Receipts').get();
      int orderCount = 0;

      for (final receiptDoc in receipts.docs) {
        final receipt = receiptDoc.data();
        final menus = (receipt['menus'] as List<dynamic>?) ?? [];

        // 각 Receipt마다 Order 문서 생성 (메뉴 1개 = Order 1개)
        for (final menu in menus) {
          if (menu is Map<String, dynamic>) {
            final menuInfo = menu['menu'] as Map<String, dynamic>?;
            if (menuInfo != null && menuInfo['id'] != null) {
              final orderRef = _firestore.collection('Orders').doc();

              await orderRef.set({
                'receiptId': receiptDoc.id,
                'storeId': receipt['storeId'] ?? '',
                'tableId': receipt['tableId'] ?? '',
                'items': [
                  {
                    'menuId': menuInfo['id'],
                    'quantity': menu['quantity'] ?? 1,
                    'status': menu['status'] ?? 'ordered',
                    'completedCount': menu['completedCount'] ?? 0,
                    'orderedAt': menu['orderedAt'],
                    'priceAtOrder': (menuInfo['price'] as num?)?.toInt() ?? 0,
                  }
                ],
                'totalPrice': ((menuInfo['price'] as num?)?.toInt() ?? 0) *
                    (menu['quantity'] as int? ?? 1),
                'createdAt': receipt['createdAt'],
                'updatedAt': receipt['updatedAt'],
              });

              orderCount++;
            }
          }
        }
      }

      developer.log('Created $orderCount order documents', name: 'MenuMigration');
      return orderCount;
    } catch (e) {
      developer.log('Error creating Orders collection: $e', name: 'MenuMigration');
      rethrow;
    }
  }

  /// Phase 3: Receipts 컬렉션 업데이트 (orders 배열 추가, menus 필드 제거)
  Future<void> updateReceiptsCollection() async {
    try {
      developer.log('Starting Receipts collection update...', name: 'MenuMigration');

      final receipts = await _firestore.collection('Receipts').get();

      for (final receiptDoc in receipts.docs) {
        // Receipt마다 생성된 Orders 조회
        final orders = await _firestore
            .collection('Orders')
            .where('receiptId', isEqualTo: receiptDoc.id)
            .get();

        final orderIds = orders.docs.map((doc) => doc.id).toList();

        // Receipt 업데이트: orders 배열 추가, menus 삭제
        await receiptDoc.reference.update({
          'orders': orderIds,
          'menus': FieldValue.delete(),
        });

        developer.log(
          'Updated Receipt ${receiptDoc.id} with ${orderIds.length} orders',
          name: 'MenuMigration',
        );
      }

      developer.log('Receipts collection update completed', name: 'MenuMigration');
    } catch (e) {
      developer.log('Error updating Receipts collection: $e', name: 'MenuMigration');
      rethrow;
    }
  }

  /// 데이터 검증: 마이그레이션 전후 일관성 확인
  Future<bool> validateMigration() async {
    try {
      developer.log('Starting migration validation...', name: 'MenuMigration');

      // 1. Menus 컬렉션 확인
      final menus = await _firestore.collection('Menus').get();
      developer.log('Menus collection: ${menus.docs.length} documents', name: 'MenuMigration');

      // 2. Orders 컬렉션 확인
      final orders = await _firestore.collection('Orders').get();
      developer.log('Orders collection: ${orders.docs.length} documents', name: 'MenuMigration');

      // 3. Receipts와 Orders 연결 확인
      final receipts = await _firestore.collection('Receipts').get();
      int totalOrdersInReceipts = 0;

      for (final receipt in receipts.docs) {
        final data = receipt.data();
        final orderIds = data['orders'] as List<dynamic>? ?? [];
        totalOrdersInReceipts += orderIds.length;

        // 각 orderIds가 실제로 존재하는지 확인
        for (final orderId in orderIds) {
          final order = await _firestore.collection('Orders').doc(orderId as String).get();
          if (!order.exists) {
            developer.log(
              'ERROR: Order $orderId referenced in Receipt ${receipt.id} does not exist!',
              name: 'MenuMigration',
            );
            return false;
          }
        }
      }

      developer.log(
        'Receipts collection: ${receipts.docs.length} documents with $totalOrdersInReceipts total orders',
        name: 'MenuMigration',
      );

      // 4. 메뉴 정보 일관성 확인
      for (final order in orders.docs) {
        final data = order.data();
        final items = data['items'] as List<dynamic>? ?? [];

        for (final item in items) {
          if (item is Map<String, dynamic>) {
            final menuId = item['menuId'] as String?;
            if (menuId != null) {
              final menu = await _firestore.collection('Menus').doc(menuId).get();
              if (!menu.exists) {
                developer.log(
                  'ERROR: Menu $menuId referenced in Order ${order.id} does not exist!',
                  name: 'MenuMigration',
                );
                return false;
              }
            }
          }
        }
      }

      developer.log('Migration validation passed!', name: 'MenuMigration');
      return true;
    } catch (e) {
      developer.log('Error validating migration: $e', name: 'MenuMigration');
      return false;
    }
  }

  /// 전체 마이그레이션 실행 (3단계 모두)
  Future<bool> executeMigration() async {
    try {
      developer.log('=== Starting complete migration ===', name: 'MenuMigration');

      // Phase 1
      await createMenusCollection();

      // Phase 2
      await createOrdersCollection();

      // Phase 3
      await updateReceiptsCollection();

      // Validation
      final isValid = await validateMigration();

      if (isValid) {
        developer.log('=== Migration completed successfully ===', name: 'MenuMigration');
        return true;
      } else {
        developer.log('=== Migration validation failed ===', name: 'MenuMigration');
        return false;
      }
    } catch (e) {
      developer.log('=== Migration failed: $e ===', name: 'MenuMigration');
      return false;
    }
  }
}
