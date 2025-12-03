import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/models/admin/store_info.dart';
import 'package:table_order/models/admin/table_model.dart';

/// 가게 도메인 Repository
/// 가게 정보와 테이블 관리를 담당하는 Firestore 데이터 접근 계층
class StoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _storesCollection = 'Stores';
  static const String _tablesCollection = 'Tables';

  // ============= Store 관련 메서드 =============

  /// 특정 가게의 정보 조회
  Future<StoreInfoModel> fetchStoreInfo(String storeId) async {
    try {
      final doc = await _firestore.collection(_storesCollection).doc(storeId).get();

      if (!doc.exists) {
        developer.log('Store not found: storeId=$storeId', name: 'StoreRepository');
        return StoreInfoModel.initial();
      }

      final data = doc.data();
      return _parseStoreInfo(data);
    } catch (e) {
      developer.log('Error fetching store info: $e', name: 'StoreRepository');
      return StoreInfoModel.initial();
    }
  }

  /// 가게 정보 수정
  Future<void> updateStoreInfo({
    required String storeId,
    required String name,
    required String notice,
  }) async {
    try {
      await _firestore.collection(_storesCollection).doc(storeId).update({
        'name': name,
        'notice': notice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Updated store info: storeId=$storeId, name=$name',
        name: 'StoreRepository',
      );
    } catch (e) {
      developer.log('Error updating store info: $e', name: 'StoreRepository');
      rethrow;
    }
  }

  // ============= Table 관련 메서드 =============

  /// 특정 가게의 모든 테이블 조회
  Future<List<TableModel>> fetchTables(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection(_tablesCollection)
          .where('storeId', isEqualTo: storeId)
          .get();

      final tables = <TableModel>[];
      for (final doc in snapshot.docs) {
        final table = _parseTable(doc.id, doc.data());
        if (table != null) {
          tables.add(table);
        }
      }

      developer.log(
        'Fetched ${tables.length} tables for storeId=$storeId',
        name: 'StoreRepository',
      );

      return tables;
    } catch (e) {
      developer.log('Error fetching tables: $e', name: 'StoreRepository');
      return [];
    }
  }

  /// 테이블 추가
  Future<void> addTable({
    required String storeId,
    required String name,
  }) async {
    try {
      await _firestore.collection(_tablesCollection).add({
        'storeId': storeId,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Added table: name=$name, storeId=$storeId',
        name: 'StoreRepository',
      );
    } catch (e) {
      developer.log('Error adding table: $e', name: 'StoreRepository');
      rethrow;
    }
  }

  /// 테이블 수정
  Future<void> updateTable({
    required String id,
    required String name,
  }) async {
    try {
      await _firestore.collection(_tablesCollection).doc(id).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('Updated table: id=$id, name=$name', name: 'StoreRepository');
    } catch (e) {
      developer.log('Error updating table: $e', name: 'StoreRepository');
      rethrow;
    }
  }

  /// 테이블 삭제
  Future<void> deleteTable(String id) async {
    try {
      await _firestore.collection(_tablesCollection).doc(id).delete();

      developer.log('Deleted table: id=$id', name: 'StoreRepository');
    } catch (e) {
      developer.log('Error deleting table: $e', name: 'StoreRepository');
      rethrow;
    }
  }

  // ============= Private 메서드 =============

  /// StoreInfoModel 데이터 파싱
  StoreInfoModel _parseStoreInfo(Map<String, dynamic>? data) {
    if (data == null) return StoreInfoModel.initial();

    try {
      return StoreInfoModel(
        storeName: data['name'] ?? '',
        notice: data['notice'] ?? '',
      );
    } catch (e) {
      developer.log('Error parsing store info: $e', name: 'StoreRepository');
      return StoreInfoModel.initial();
    }
  }

  /// TableModel 데이터 파싱
  TableModel? _parseTable(String id, Map<String, dynamic> data) {
    try {
      final storeId = data['storeId'];
      final storeIdStr = storeId is int ? storeId.toString() : (storeId as String? ?? '');

      return TableModel(
        id: id,
        name: data['name'] ?? '',
        storeId: storeIdStr,
      );
    } catch (e) {
      developer.log('Error parsing table: $e', name: 'StoreRepository');
      return null;
    }
  }
}
