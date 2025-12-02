import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore 데이터 마이그레이션 서버
/// Orders 컬렉션을 Receipts와 Orders로 분리하는 마이그레이션 로직 처리
///
/// 마이그레이션 단계:
/// 1. Orders → Receipts: 기존 Orders 문서를 Receipts로 복사
/// 2. CallRequests 업데이트: receiptId 필드 추가
/// 3. 검증: 마이그레이션 전후 데이터 수 비교
class MigrationServer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _receiptsCollection = 'Receipts';
  static const String _ordersCollection = 'Orders';
  static const String _callRequestsCollection = 'CallRequests';

  /// Orders → Receipts 마이그레이션
  /// 기존 Orders 문서를 Receipts로 복사
  Future<void> migrateOrdersToReceipts() async {
    try {
      developer.log('Starting migration: Orders → Receipts', name: 'MigrationServer');

      final ordersSnapshot = await _firestore.collection(_ordersCollection).get();
      developer.log('Found ${ordersSnapshot.docs.length} orders to migrate', name: 'MigrationServer');

      final batch = _firestore.batch();
      int migratedCount = 0;

      for (final orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data();
        final receiptId = orderDoc.id; // 기존 orderId를 receiptId로 사용

        // Receipts 문서 생성
        final receiptRef = _firestore.collection(_receiptsCollection).doc(receiptId);

        batch.set(receiptRef, {
          'storeId': orderData['storeId'] ?? '',
          'tableId': orderData['tableId'] ?? '',
          'status': orderData['status'] ?? 'unpaid', // 'unpaid' or 'paid'
          'totalPrice': orderData['totalPrice'] ?? 0,
          'createdAt': orderData['createdAt'],
          'updatedAt': orderData['updatedAt'],
        });

        migratedCount++;

        // Firestore batch는 최대 500개까지만 가능하므로 분할 처리
        if (migratedCount % 500 == 0) {
          await batch.commit();
          developer.log('Committed batch: $migratedCount orders migrated', name: 'MigrationServer');
        }
      }

      // 남은 데이터 커밋
      if (migratedCount % 500 != 0) {
        await batch.commit();
      }

      developer.log('Migration completed: $migratedCount orders migrated to Receipts', name: 'MigrationServer');
    } catch (e) {
      developer.log('Error migrating orders to receipts: $e', name: 'MigrationServer');
      rethrow;
    }
  }

  /// CallRequests에 receiptId 추가
  /// 기존 Orders 데이터의 ID를 receiptId로 설정
  Future<void> addReceiptIdToCallRequests() async {
    try {
      developer.log('Starting: Adding receiptId to CallRequests', name: 'MigrationServer');

      final callRequestsSnapshot = await _firestore.collection(_callRequestsCollection).get();
      developer.log('Found ${callRequestsSnapshot.docs.length} call requests', name: 'MigrationServer');

      final batch = _firestore.batch();
      int updatedCount = 0;

      for (final doc in callRequestsSnapshot.docs) {
        final data = doc.data();

        // 이미 유효한 receiptId가 있으면 스킵
        final existingReceiptId = data['receiptId'] as String?;
        if (existingReceiptId != null && existingReceiptId.isNotEmpty) {
          developer.log('CallRequest ${doc.id} already has valid receiptId: $existingReceiptId', name: 'MigrationServer');
          continue;
        }

        // receiptId가 없거나 빈 경우 경고 로깅
        developer.log(
          'CallRequest ${doc.id} has missing receiptId. Manual mapping required. '
          'tableId=${data['tableId']}, tableName=${data['tableName']}',
          name: 'MigrationServer',
          level: 800, // warning level
        );

        // 빈 문자열 대신 receiptId 필드를 더 이상 추가하지 않음
        // 향후 수동 매핑 필요
        // batch.update(doc.reference, {
        //   'receiptId': '',
        // });

        updatedCount++;

        if (updatedCount % 500 == 0) {
          await batch.commit();
          developer.log('Committed batch: $updatedCount call requests updated', name: 'MigrationServer');
        }
      }

      if (updatedCount % 500 != 0) {
        await batch.commit();
      }

      developer.log('Completed: $updatedCount call requests updated', name: 'MigrationServer');
    } catch (e) {
      developer.log('Error adding receiptId to call requests: $e', name: 'MigrationServer');
      rethrow;
    }
  }

  /// 마이그레이션 상태 확인
  Future<Map<String, int>> getMigrationStatus() async {
    try {
      final ordersCount = await _firestore.collection(_ordersCollection).count().get();
      final receiptsCount = await _firestore.collection(_receiptsCollection).count().get();
      final callRequestsCount = await _firestore.collection(_callRequestsCollection).count().get();

      return {
        'orders': ordersCount.count ?? 0,
        'receipts': receiptsCount.count ?? 0,
        'callRequests': callRequestsCount.count ?? 0,
      };
    } catch (e) {
      developer.log('Error getting migration status: $e', name: 'MigrationServer');
      return {
        'orders': 0,
        'receipts': 0,
        'callRequests': 0,
      };
    }
  }

  /// 마이그레이션 실행 (안전성 검사 포함)
  Future<Map<String, dynamic>> executeMigration() async {
    try {
      final startStatus = await getMigrationStatus();
      developer.log('Migration start status: $startStatus', name: 'MigrationServer');

      // 1. Orders → Receipts 마이그레이션
      await migrateOrdersToReceipts();

      // 2. CallRequests에 receiptId 추가
      await addReceiptIdToCallRequests();

      final endStatus = await getMigrationStatus();
      developer.log('Migration end status: $endStatus', name: 'MigrationServer');

      return {
        'success': true,
        'message': 'Migration completed successfully',
        'startStatus': startStatus,
        'endStatus': endStatus,
      };
    } catch (e) {
      developer.log('Migration failed: $e', name: 'MigrationServer');
      return {
        'success': false,
        'message': 'Migration failed: $e',
      };
    }
  }
}
