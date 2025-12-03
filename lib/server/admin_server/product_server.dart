import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/models/admin/product.dart';

class ProductServer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Menus';

  /// 모든 Product 조회
  Future<List<Product>> fetchProducts() async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);

      return await collectionRef.get().then((QuerySnapshot snapshot) {
        List<QueryDocumentSnapshot> list = snapshot.docs;
        List<Product> products = [];

        for (var doc in list) {
          final product = _parseProduct(doc.id, doc.data() as Map<String, dynamic>?);
          if (product != null) {
            products.add(product);
          }
        }

        return products;
      });
    } catch (e) {
      developer.log('Error fetching products: $e', name: 'ProductServer');
      return [];
    }
  }

  /// 특정 가게의 Product 목록 조회 (메뉴 추가 시 사용)
  Future<List<Map<String, dynamic>>> fetchProductsByStore(String storeId) async {
    try {
      developer.log(
        'Fetching products for storeId=$storeId',
        name: 'ProductServer',
      );

      final productsSnapshot = await _firestore
          .collection(_collectionName)
          .where('storeId', isEqualTo: storeId)
          .where('isActive', isEqualTo: true)
          .get();

      final products = <Map<String, dynamic>>[];

      developer.log(
        'Found ${productsSnapshot.docs.length} active products',
        name: 'ProductServer',
      );

      for (final doc in productsSnapshot.docs) {
        final data = doc.data();
        products.add({
          'id': doc.id,
          'name': data['name'] ?? '미정의',
          'price': (data['price'] is int) ? data['price'] : int.tryParse(data['price']?.toString() ?? '0') ?? 0,
          'categoryId': data['categoryId'],
          'categoryName': data['categoryName'] ?? '기타',
        });

        developer.log(
          'Product: name=${data['name']}, price=${data['price']}',
          name: 'ProductServer',
        );
      }

      return products;
    } catch (e) {
      developer.log(
        'Error fetching products by store: $e',
        name: 'ProductServer',
      );
      return [];
    }
  }

  /// Product 추가
  Future<String> addProduct(Product p) async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);

      // Firestore 자동 생성 ID 사용
      final newDocRef = collectionRef.doc();
      await newDocRef.set(_productToMap(p));
      return newDocRef.id;
    } catch (e) {
      developer.log('Error adding product: $e', name: 'ProductServer');
      return '';
    }
  }

  /// Product 업데이트
  Future<void> updateProduct(String id, Product updated) async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);
      final DocumentReference docRef = collectionRef.doc(id);

      await docRef.update(_productToMap(updated));
    } catch (e) {
      developer.log('Error updating product: $e', name: 'ProductServer');
    }
  }

  /// Product 삭제
  Future<void> deleteProduct(String id) async {
    try {
      final CollectionReference collectionRef =
          _firestore.collection(_collectionName);
      final DocumentReference docRef = collectionRef.doc(id);

      await docRef.delete();
    } catch (e) {
      developer.log('Error deleting product: $e', name: 'ProductServer');
    }
  }

  /// Product을 Map으로 변환
  Map<String, dynamic> _productToMap(Product p) {
    return {
      'name': p.name,
      'price': int.tryParse(p.price) ?? 0,
      'isSoldOut': p.isSoldOut,
      'isActive': p.isActive,
      'description': p.description,
      'storeId': p.storeId,
      'categoryId': p.categoryId,
      'imageUrl': p.imageUrl,
    };
  }

  /// Product 데이터 파싱
  Product? _parseProduct(String id, Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      final storeId = data['storeId'];
      final storeIdStr = storeId is int ? storeId.toString() : (storeId as String? ?? '');

      return Product(
        id: id,
        storeId: storeIdStr,
        name: data['name'] ?? '',
        price: data['price']?.toString() ?? '0',
        isSoldOut: data['isSoldOut'] ?? false,
        isActive: data['isActive'] ?? true,
        description: data['description'] ?? '',
        categoryId: data['categoryId'] ?? '',
        imageUrl: data['imageUrl'],
      );
    } catch (e) {
      developer.log('Error parsing product: $e', name: 'ProductServer');
      return null;
    }
  }
}
