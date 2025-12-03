import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:table_order/models/admin/category.dart';
import 'package:table_order/models/admin/product.dart';
import 'package:table_order/service/admin/menu_service.dart';

/// 메뉴 도메인 Provider
/// 카테고리와 상품의 UI 상태 관리
class MenuProvider extends ChangeNotifier {
  final MenuService _service = MenuService();

  List<Category> _categories = [];
  List<Product> _products = [];
  bool _loading = false;
  String? _error;

  // Getters
  List<Category> get categories => _categories;
  List<Product> get products => _products;
  bool get loading => _loading;
  String? get error => _error;

  // ============= 카테고리 관련 메서드 =============

  /// 특정 가게의 메뉴 데이터 로드 (카테고리 + 상품)
  Future<void> loadMenuData(String storeId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      developer.log(
        'Loading menu data for storeId=$storeId',
        name: 'MenuProvider',
      );

      final categoriesFuture = _service.getCategories(storeId);
      final productsFuture = _service.getProductsByStore(storeId);

      _categories = await categoriesFuture;
      _products = await productsFuture;

      developer.log(
        'Loaded ${_categories.length} categories and ${_products.length} products',
        name: 'MenuProvider',
      );

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load menu data: $e';
      developer.log(_error!, name: 'MenuProvider');
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 카테고리 생성
  Future<void> addCategory({
    required String storeId,
    required String name,
  }) async {
    try {
      _error = null;
      await _service.createCategory(
        storeId: storeId,
        name: name,
      );

      developer.log(
        'Category added: name=$name',
        name: 'MenuProvider',
      );

      // 카테고리 추가 후 메뉴 데이터 새로 로드
      await loadMenuData(storeId);
    } catch (e) {
      _error = 'Failed to add category: $e';
      developer.log(_error!, name: 'MenuProvider');
      notifyListeners();
    }
  }

  /// 카테고리 수정
  Future<void> updateCategory({
    required String id,
    required String name,
    required bool active,
    required int order,
    required String storeId,
  }) async {
    try {
      _error = null;
      await _service.updateCategory(
        id: id,
        name: name,
        active: active,
        order: order,
      );

      developer.log(
        'Category updated: id=$id',
        name: 'MenuProvider',
      );

      // 카테고리 수정 후 메뉴 데이터 새로 로드
      await loadMenuData(storeId);
    } catch (e) {
      _error = 'Failed to update category: $e';
      developer.log(_error!, name: 'MenuProvider');
      notifyListeners();
    }
  }

  /// 카테고리 삭제
  Future<void> deleteCategory({
    required String id,
    required String storeId,
  }) async {
    try {
      _error = null;
      await _service.deleteCategory(id);

      developer.log(
        'Category deleted: id=$id',
        name: 'MenuProvider',
      );

      // 카테고리 삭제 후 메뉴 데이터 새로 로드
      await loadMenuData(storeId);
    } catch (e) {
      _error = 'Failed to delete category: $e';
      developer.log(_error!, name: 'MenuProvider');
      notifyListeners();
    }
  }

  // ============= 상품 관련 메서드 =============

  /// 상품 추가
  Future<void> addProduct({
    required Product product,
    required String storeId,
  }) async {
    try {
      _error = null;
      final productId = await _service.createProduct(product);

      developer.log(
        'Product added: id=$productId, name=${product.name}',
        name: 'MenuProvider',
      );

      // 상품 추가 후 메뉴 데이터 새로 로드
      await loadMenuData(storeId);
    } catch (e) {
      _error = 'Failed to add product: $e';
      developer.log(_error!, name: 'MenuProvider');
      notifyListeners();
    }
  }

  /// 상품 수정
  Future<void> updateProduct({
    required String id,
    required Product product,
    required String storeId,
  }) async {
    try {
      _error = null;
      await _service.updateProduct(id, product);

      developer.log(
        'Product updated: id=$id',
        name: 'MenuProvider',
      );

      // 상품 수정 후 메뉴 데이터 새로 로드
      await loadMenuData(storeId);
    } catch (e) {
      _error = 'Failed to update product: $e';
      developer.log(_error!, name: 'MenuProvider');
      notifyListeners();
    }
  }

  /// 상품 삭제
  Future<void> deleteProduct({
    required String id,
    required String storeId,
  }) async {
    try {
      _error = null;
      await _service.deleteProduct(id);

      developer.log(
        'Product deleted: id=$id',
        name: 'MenuProvider',
      );

      // 상품 삭제 후 메뉴 데이터 새로 로드
      await loadMenuData(storeId);
    } catch (e) {
      _error = 'Failed to delete product: $e';
      developer.log(_error!, name: 'MenuProvider');
      notifyListeners();
    }
  }

  /// 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
