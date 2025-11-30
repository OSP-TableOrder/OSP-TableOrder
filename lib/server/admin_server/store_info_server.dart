import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/models/admin/store_info.dart';

class StoreInfoServer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Stores';

  /// 특정 가게의 정보 조회
  Future<StoreInfoModel> fetchStoreInfo(String storeId) async {
    try {
      final DocumentReference docRef = _firestore
          .collection(_collectionName)
          .doc(storeId);

      return await docRef.get().then((DocumentSnapshot snapshot) {
        if (!snapshot.exists) {
          return StoreInfoModel.initial();
        }

        final data = snapshot.data() as Map<String, dynamic>?;
        return _parseStoreInfo(data);
      });
    } catch (e) {
      developer.log('Error fetching store info: $e', name: 'StoreInfoServer');
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
      final DocumentReference docRef = _firestore
          .collection(_collectionName)
          .doc(storeId);

      await docRef.update({
        'name': name, // 'name' 필드로 수정 (store 생성 시와 동일한 필드명)
        'notice': notice,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('Error updating store info: $e', name: 'StoreInfoServer');
    }
  }

  /// StoreInfoModel 데이터 파싱
  StoreInfoModel _parseStoreInfo(Map<String, dynamic>? data) {
    if (data == null) return StoreInfoModel.initial();

    try {
      return StoreInfoModel(
        storeName: data['name'] ?? '', // 'name' 필드 사용 (store 생성 시 사용되는 필드)
        notice: data['notice'] ?? '',
      );
    } catch (e) {
      developer.log('Error parsing store info: $e', name: 'StoreInfoServer');
      return StoreInfoModel.initial();
    }
  }
}
