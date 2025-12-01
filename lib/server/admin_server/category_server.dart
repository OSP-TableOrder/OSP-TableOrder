import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/models/admin/category.dart';

class CategoryServer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Categories';

  /// 특정 가게의 모든 카테고리 조회
  Future<List<Category>> fetchCategories(String storeId) async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);

      return await collectionRef
          .where('storeId', isEqualTo: storeId)
          .get()
          .then((QuerySnapshot snapshot) {
        List<QueryDocumentSnapshot> list = snapshot.docs;
        List<Category> categories = [];

        for (var doc in list) {
          final category = _parseCategory(doc.id, doc.data() as Map<String, dynamic>?);
          if (category != null) {
            categories.add(category);
          }
        }

        // 메모리에서 order 필드로 정렬
        categories.sort((a, b) => a.order.compareTo(b.order));

        return categories;
      });
    } catch (e) {
      developer.log('Error fetching categories: $e', name: 'CategoryServer');
      return [];
    }
  }

  /// 카테고리 추가
  Future<void> addCategory({
    required String storeId,
    required String name,
    bool active = true,
    int order = 0,
  }) async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);

      // Firestore 자동 생성 ID 사용
      final newDocRef = collectionRef.doc();

      await newDocRef.set({
        'storeId': storeId,
        'name': name,
        'active': active,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('Error adding category: $e', name: 'CategoryServer');
    }
  }

  /// 카테고리 수정
  Future<void> updateCategory({
    required String id,
    required String name,
    required bool active,
    required int order,
  }) async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);
      final DocumentReference docRef = collectionRef.doc(id);

      await docRef.update({
        'name': name,
        'active': active,
        'order': order,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('Error updating category: $e', name: 'CategoryServer');
    }
  }

  /// 카테고리 삭제
  Future<void> deleteCategory(String id) async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);
      final DocumentReference docRef = collectionRef.doc(id);

      await docRef.delete();
    } catch (e) {
      developer.log('Error deleting category: $e', name: 'CategoryServer');
    }
  }

  /// Category 데이터 파싱
  Category? _parseCategory(String id, Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      final storeId = data['storeId'];
      final storeIdStr = storeId is int ? storeId.toString() : (storeId as String? ?? '');

      return Category(
        id: id,
        storeId: storeIdStr,
        name: data['name'] ?? '',
        active: data['active'] ?? true,
        order: data['order'] ?? 0,
      );
    } catch (e) {
      developer.log('Error parsing category: $e', name: 'CategoryServer');
      return null;
    }
  }
}
