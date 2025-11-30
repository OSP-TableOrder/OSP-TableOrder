import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

class TableServer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Tables';

  /// 테이블 이름 조회
  Future<String?> fetchTableName(String tableId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(tableId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      return data?['name'] as String?;
    } catch (e) {
      developer.log('Error fetching table name: $e', name: 'TableServer');
      return null;
    }
  }
}
