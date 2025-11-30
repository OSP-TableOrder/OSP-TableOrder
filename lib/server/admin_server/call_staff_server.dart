import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/models/admin/call_staff_log.dart';

class CallStaffServer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'CallRequests';

  Future<List<CallStaffLog>> fetchCallLogs(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('storeId', isEqualTo: storeId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['createdAt'] as Timestamp?;
        final time = timestamp != null ? _formatTime(timestamp.toDate()) : '-';

        return CallStaffLog(
          id: doc.id,
          tableId: (data['tableId'] as String?) ?? '',
          table: (data['tableName'] as String?) ??
              (data['tableId'] as String?) ??
              '테이블',
          message: (data['message'] as String?) ?? '',
          time: time,
          resolved: ((data['status'] as String?) ?? 'pending') != 'pending',
        );
      }).toList();
    } catch (e) {
      developer.log('Error fetching call logs: $e', name: 'CallStaffServer');
      return [];
    }
  }

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
    } catch (e) {
      developer.log('Error adding call log: $e', name: 'CallStaffServer');
      rethrow;
    }
  }

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

      for (final doc in query.docs) {
        await doc.reference.update({
          'status': 'resolved',
          'updatedAt': FieldValue.serverTimestamp(),
          'resolvedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      developer.log('Error resolving call logs: $e', name: 'CallStaffServer');
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
