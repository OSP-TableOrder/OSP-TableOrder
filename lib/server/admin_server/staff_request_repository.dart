import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/models/admin/call_staff_log.dart';

/// 직원 호출 도메인 Repository
/// 직원 호출 요청 관리를 담당하는 Firestore 데이터 접근 계층
class StaffRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'CallRequests';

  /// 특정 가게의 대기 중인 직원 호출 로그 조회
  Future<List<CallStaffLog>> fetchCallLogs(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('storeId', isEqualTo: storeId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final logs = <CallStaffLog>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();

        // 중복 파싱 제거: createdAt을 한 번만 파싱
        DateTime? createdAt;
        final createdAtTimestamp = data['createdAt'] as Timestamp?;
        if (createdAtTimestamp != null) {
          createdAt = createdAtTimestamp.toDate();
        }

        final time = createdAt != null ? _formatTime(createdAt) : '-';

        logs.add(CallStaffLog(
          id: doc.id,
          storeId: (data['storeId'] as String?) ?? '',
          tableId: (data['tableId'] as String?) ?? '',
          table: (data['tableName'] as String?) ?? (data['tableId'] as String?) ?? '테이블',
          message: (data['message'] as String?) ?? '',
          time: time,
          resolved: ((data['status'] as String?) ?? 'pending') != 'pending',
          receiptId: (data['receiptId'] as String?),
          createdAt: createdAt,
        ));
      }

      developer.log(
        'Fetched ${logs.length} pending call requests for storeId=$storeId',
        name: 'StaffRequestRepository',
      );

      return logs;
    } catch (e) {
      developer.log('Error fetching call logs: $e', name: 'StaffRequestRepository');
      return [];
    }
  }

  /// 직원 호출 요청 생성
  Future<void> addCallLog({
    required String storeId,
    required String tableId,
    required String tableName,
    required String receiptId,
    required String message,
  }) async {
    try {
      await _firestore.collection(_collectionName).add({
        'storeId': storeId,
        'tableId': tableId,
        'tableName': tableName,
        'receiptId': receiptId,
        'message': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Added call request: tableId=$tableId, receiptId=$receiptId',
        name: 'StaffRequestRepository',
      );
    } catch (e) {
      developer.log('Error adding call log: $e', name: 'StaffRequestRepository');
      rethrow;
    }
  }

  /// 직원 호출 요청 해결 (pending -> resolved)
  Future<void> resolveCallLogs({
    required String storeId,
    required String tableId,
  }) async {
    try {
      final query = await _firestore
          .collection(_collectionName)
          .where('storeId', isEqualTo: storeId)
          .where('tableId', isEqualTo: tableId)
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _firestore.batch();

      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'status': 'resolved',
          'updatedAt': FieldValue.serverTimestamp(),
          'resolvedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      developer.log(
        'Resolved ${query.docs.length} call requests for tableId=$tableId',
        name: 'StaffRequestRepository',
      );
    } catch (e) {
      developer.log('Error resolving call logs: $e', name: 'StaffRequestRepository');
      rethrow;
    }
  }

  // ============= Private 메서드 =============

  /// 시간 포맷팅
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
