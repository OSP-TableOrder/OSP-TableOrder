import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/models/admin/category.dart';
import 'package:table_order/models/admin/product.dart';
import 'package:table_order/models/customer/menu.dart';

/// 메뉴 도메인 Repository
/// 카테고리와 상품 관리를 담당하는 Firestore 데이터 접근 계층
///
/// Collections:
/// - Categories: 카테고리 관리 (admin)
/// - Menus: 상품/메뉴 관리 (admin, normalized from Orders)
class MenuRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _categoriesCollection = 'Categories';
  static const String _productsCollection = 'Menus';

  // ============= Category 관련 메서드 =============

  /// 특정 가게의 모든 카테고리 조회
  Future<List<Category>> fetchCategories(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection(_categoriesCollection)
          .where('storeId', isEqualTo: storeId)
          .get();

      final categories = <Category>[];
      for (final doc in snapshot.docs) {
        final category = _parseCategory(doc.id, doc.data());
        if (category != null) {
          categories.add(category);
        }
      }

      // order 필드로 정렬
      categories.sort((a, b) => a.order.compareTo(b.order));

      developer.log(
        'Fetched ${categories.length} categories for storeId=$storeId',
        name: 'MenuRepository',
      );

      return categories;
    } catch (e) {
      developer.log('Error fetching categories: $e', name: 'MenuRepository');
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
      await _firestore.collection(_categoriesCollection).add({
        'storeId': storeId,
        'name': name,
        'active': active,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Added category: name=$name, storeId=$storeId',
        name: 'MenuRepository',
      );
    } catch (e) {
      developer.log('Error adding category: $e', name: 'MenuRepository');
      rethrow;
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
      await _firestore.collection(_categoriesCollection).doc(id).update({
        'name': name,
        'active': active,
        'order': order,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('Updated category: id=$id', name: 'MenuRepository');
    } catch (e) {
      developer.log('Error updating category: $e', name: 'MenuRepository');
      rethrow;
    }
  }

  /// 카테고리 삭제
  Future<void> deleteCategory(String id) async {
    try {
      await _firestore.collection(_categoriesCollection).doc(id).delete();

      developer.log('Deleted category: id=$id', name: 'MenuRepository');
    } catch (e) {
      developer.log('Error deleting category: $e', name: 'MenuRepository');
      rethrow;
    }
  }

  // ============= Product 관련 메서드 =============

  /// 모든 상품 조회
  Future<List<Product>> fetchProducts() async {
    try {
      final snapshot = await _firestore.collection(_productsCollection).get();

      final products = <Product>[];
      for (final doc in snapshot.docs) {
        final product = _parseProduct(doc.id, doc.data());
        if (product != null) {
          products.add(product);
        }
      }

      developer.log(
        'Fetched ${products.length} products',
        name: 'MenuRepository',
      );

      return products;
    } catch (e) {
      developer.log('Error fetching products: $e', name: 'MenuRepository');
      return [];
    }
  }

  /// 특정 가게의 활성 상품 조회
  Future<List<Product>> fetchProductsByStore(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('storeId', isEqualTo: storeId)
          .where('isActive', isEqualTo: true)
          .get();

      final products = <Product>[];
      for (final doc in snapshot.docs) {
        final product = _parseProduct(doc.id, doc.data());
        if (product != null) {
          products.add(product);
        }
      }

      developer.log(
        'Fetched ${products.length} active products for storeId=$storeId',
        name: 'MenuRepository',
      );

      return products;
    } catch (e) {
      developer.log('Error fetching products by store: $e', name: 'MenuRepository');
      return [];
    }
  }

  /// 상품 추가
  Future<String> addProduct(Product product) async {
    try {
      final docRef = await _firestore
          .collection(_productsCollection)
          .add(_productToMap(product));

      developer.log(
        'Added product: name=${product.name}, id=${docRef.id}',
        name: 'MenuRepository',
      );

      return docRef.id;
    } catch (e) {
      developer.log('Error adding product: $e', name: 'MenuRepository');
      rethrow;
    }
  }

  /// 상품 수정
  Future<void> updateProduct(String id, Product product) async {
    try {
      await _firestore
          .collection(_productsCollection)
          .doc(id)
          .update(_productToMap(product));

      developer.log('Updated product: id=$id', name: 'MenuRepository');
    } catch (e) {
      developer.log('Error updating product: $e', name: 'MenuRepository');
      rethrow;
    }
  }

  /// 상품 삭제
  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection(_productsCollection).doc(id).delete();

      developer.log('Deleted product: id=$id', name: 'MenuRepository');
    } catch (e) {
      developer.log('Error deleting product: $e', name: 'MenuRepository');
      rethrow;
    }
  }

  // ============= Private 메서드 =============

  /// Category 데이터 파싱
  Category? _parseCategory(String id, Map<String, dynamic> data) {
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
      developer.log('Error parsing category: $e', name: 'MenuRepository');
      return null;
    }
  }

  /// Product 데이터 파싱
  Product? _parseProduct(String id, Map<String, dynamic> data) {
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
      developer.log('Error parsing product: $e', name: 'MenuRepository');
      return null;
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

  // ============= Normalized Menu Collection 관련 메서드 =============
  // (MenuMigration을 통해 생성되는 정규화된 Menus 컬렉션)

  /// 특정 메뉴를 ID로 조회
  Future<Menu?> getMenuById(String menuId) async {
    try {
      final doc = await _firestore
          .collection(_productsCollection)
          .doc(menuId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Menu.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
    } catch (e) {
      developer.log('Error fetching menu by id: $e', name: 'MenuRepository');
      return null;
    }
  }

  /// 특정 가게의 모든 활성 메뉴 조회
  Future<List<Menu>> getMenusByStore(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('storeId', isEqualTo: storeId)
          .where('isActive', isEqualTo: true)
          .get();

      final menus = <Menu>[];
      for (final doc in snapshot.docs) {
        try {
          final menu = Menu.fromJson({
            ...doc.data(),
            'id': doc.id,
          });
          menus.add(menu);
        } catch (e) {
          developer.log(
            'Error parsing menu document ${doc.id}: $e',
            name: 'MenuRepository',
          );
        }
      }

      developer.log(
        'Fetched ${menus.length} active menus for storeId=$storeId',
        name: 'MenuRepository',
      );

      return menus;
    } catch (e) {
      developer.log(
        'Error fetching menus by store: $e',
        name: 'MenuRepository',
      );
      return [];
    }
  }

  /// 특정 가게의 특정 카테고리 메뉴 조회
  Future<List<Menu>> getMenusByCategory(
    String storeId,
    String categoryId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('storeId', isEqualTo: storeId)
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .get();

      final menus = <Menu>[];
      for (final doc in snapshot.docs) {
        try {
          final menu = Menu.fromJson({
            ...doc.data(),
            'id': doc.id,
          });
          menus.add(menu);
        } catch (e) {
          developer.log(
            'Error parsing menu document ${doc.id}: $e',
            name: 'MenuRepository',
          );
        }
      }

      developer.log(
        'Fetched ${menus.length} menus for storeId=$storeId, categoryId=$categoryId',
        name: 'MenuRepository',
      );

      return menus;
    } catch (e) {
      developer.log(
        'Error fetching menus by category: $e',
        name: 'MenuRepository',
      );
      return [];
    }
  }

  /// 여러 메뉴를 ID 리스트로 배치 조회 (Orders의 items 조회 시 효율적)
  Future<List<Menu>> getMenusByIds(List<String> menuIds) async {
    if (menuIds.isEmpty) {
      return [];
    }

    try {
      // Firestore의 'in' 쿼리는 최대 10개까지 지원
      // 더 많은 경우 청크로 나누어 조회
      final menus = <Menu>[];
      const maxBatchSize = 10;

      for (var i = 0; i < menuIds.length; i += maxBatchSize) {
        final batch = menuIds.sublist(
          i,
          (i + maxBatchSize > menuIds.length) ? menuIds.length : i + maxBatchSize,
        );

        final snapshot = await _firestore
            .collection(_productsCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          try {
            final menu = Menu.fromJson({
              ...doc.data(),
              'id': doc.id,
            });
            menus.add(menu);
          } catch (e) {
            developer.log(
              'Error parsing menu document ${doc.id}: $e',
              name: 'MenuRepository',
            );
          }
        }
      }

      developer.log(
        'Fetched ${menus.length} menus from ${menuIds.length} menu IDs',
        name: 'MenuRepository',
      );

      return menus;
    } catch (e) {
      developer.log('Error fetching menus by ids: $e', name: 'MenuRepository');
      return [];
    }
  }

  /// 메뉴 가격 업데이트
  Future<bool> updateMenuPrice(String menuId, int newPrice) async {
    try {
      await _firestore.collection(_productsCollection).doc(menuId).update({
        'price': newPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Updated menu price: menuId=$menuId, newPrice=$newPrice',
        name: 'MenuRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error updating menu price: $e', name: 'MenuRepository');
      return false;
    }
  }

  /// 메뉴 품절 상태 업데이트
  Future<bool> updateMenuSoldOut(String menuId, bool isSoldOut) async {
    try {
      await _firestore.collection(_productsCollection).doc(menuId).update({
        'isSoldOut': isSoldOut,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Updated menu soldOut status: menuId=$menuId, isSoldOut=$isSoldOut',
        name: 'MenuRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error updating menu soldOut status: $e', name: 'MenuRepository');
      return false;
    }
  }

  /// 메뉴 활성화 상태 업데이트
  Future<bool> updateMenuActive(String menuId, bool isActive) async {
    try {
      await _firestore.collection(_productsCollection).doc(menuId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Updated menu active status: menuId=$menuId, isActive=$isActive',
        name: 'MenuRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error updating menu active status: $e', name: 'MenuRepository');
      return false;
    }
  }

  /// 메뉴 추천 여부 업데이트
  Future<bool> updateMenuRecommended(String menuId, bool isRecommended) async {
    try {
      await _firestore.collection(_productsCollection).doc(menuId).update({
        'isRecommended': isRecommended,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Updated menu recommended status: menuId=$menuId, isRecommended=$isRecommended',
        name: 'MenuRepository',
      );

      return true;
    } catch (e) {
      developer.log('Error updating menu recommended status: $e', name: 'MenuRepository');
      return false;
    }
  }
}
