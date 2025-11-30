import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/models/admin/table_model.dart';

class TableConnectServer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Tables';

  /// 특정 가게의 모든 테이블 조회
  Future<List<TableModel>> fetchTables(String storeId) async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);

      return await collectionRef
          .where('storeId', isEqualTo: storeId)
          .get()
          .then((QuerySnapshot snapshot) {
        List<QueryDocumentSnapshot> list = snapshot.docs;
        List<TableModel> tables = [];

        for (var doc in list) {
          final table = _parseTable(doc.id, doc.data() as Map<String, dynamic>?);
          if (table != null) {
            tables.add(table);
          }
        }

        return tables;
      });
    } catch (e) {
      developer.log('Error fetching tables: $e', name: 'TableConnectServer');
      return [];
    }
  }

  /// 테이블 추가
  Future<void> addTable({
    required String storeId,
    required String name,
  }) async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);

      // Firestore 자동 생성 ID 사용
      final newDocRef = collectionRef.doc();

      await newDocRef.set({
        'storeId': storeId,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('Error adding table: $e', name: 'TableConnectServer');
    }
  }

  /// 테이블 수정
  Future<void> updateTable({
    required String id,
    required String name,
  }) async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);
      final DocumentReference docRef = collectionRef.doc(id);

      await docRef.update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('Error updating table: $e', name: 'TableConnectServer');
    }
  }

  /// 테이블 삭제
  Future<void> deleteTable(String id) async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);
      final DocumentReference docRef = collectionRef.doc(id);

      await docRef.delete();
    } catch (e) {
      developer.log('Error deleting table: $e', name: 'TableConnectServer');
    }
  }

  /// TableModel 데이터 파싱
  TableModel? _parseTable(String id, Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      final storeId = data['storeId'];
      final storeIdStr = storeId is int ? storeId.toString() : (storeId as String? ?? '');

      return TableModel(
        id: id,
        name: data['name'] ?? '',
        storeId: storeIdStr,
      );
    } catch (e) {
      developer.log('Error parsing table: $e', name: 'TableConnectServer');
      return null;
    }
  }
}
