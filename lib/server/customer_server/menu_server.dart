import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/models/customer/menu.dart';

class MenuServer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Menus';

  /// Store ID로 메뉴 조회
  Future<List<Menu>> fetchMenusByStoreId(String storeId) async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);

      return await collectionRef
          .where('storeId', isEqualTo: storeId)
          .get()
          .then((QuerySnapshot snapshot) {
        List<QueryDocumentSnapshot> list = snapshot.docs;
        List<Menu> menus = [];

        for (var doc in list) {
          final menu = _parseMenu(
            doc.id,
            doc.data() as Map<String, dynamic>?,
          );
          if (menu != null) {
            menus.add(menu);
          }
        }

        return menus;
      });
    } catch (e) {
      developer.log('Error fetching menus: $e', name: 'MenuServer');
      return [];
    }
  }

  /// 메뉴 ID로 조회
  Future<Menu?> findById(String menuId) async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);
      final DocumentReference docRef = collectionRef.doc(menuId);

      return await docRef.get().then((DocumentSnapshot snapshot) {
        if (!snapshot.exists) return null;

        return _parseMenu(menuId, snapshot.data() as Map<String, dynamic>?);
      });
    } catch (e) {
      developer.log('Error fetching menu: $e', name: 'MenuServer');
      return null;
    }
  }

  /// Menu 데이터 파싱
  Menu? _parseMenu(String id, Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      final storeId = data['storeId'];
      final storeIdStr = storeId is int ? storeId.toString() : (storeId as String? ?? '');

      final price = data['price'];
      final priceInt = price is int ? price : (int.tryParse(price as String? ?? '0') ?? 0);

      return Menu(
        id: id,
        storeId: storeIdStr,
        categoryId: data['categoryId'] ?? data['category'], // 하위 호환성
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        imageUrl: data['imageUrl'],
        price: priceInt,
        isSoldOut: data['isSoldOut'] ?? false,
        isRecommended: data['isRecommended'] ?? false,
      );
    } catch (e) {
      developer.log('Error parsing menu: $e', name: 'MenuServer');
      return null;
    }
  }
}
