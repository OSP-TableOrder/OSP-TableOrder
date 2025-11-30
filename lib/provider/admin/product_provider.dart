import 'package:flutter/material.dart';
import 'package:table_order/models/admin/product.dart';
import 'package:table_order/service/admin/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<Product> _products = [];
  List<Product> get products => _products;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// 모든 상품 로드
  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _service.getProducts();
    } catch (e) {
      _error = 'Failed to load products: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 상품 추가
  Future<String> addProduct(Product p) async {
    try {
      _error = null;
      final productId = await _service.add(p);
      await loadProducts();
      return productId;
    } catch (e) {
      _error = 'Failed to add product: $e';
      notifyListeners();
      return '';
    }
  }

  /// 상품 수정
  Future<void> updateProduct(String id, Product updated) async {
    try {
      _error = null;
      await _service.update(id, updated);
      await loadProducts();
    } catch (e) {
      _error = 'Failed to update product: $e';
      notifyListeners();
    }
  }

  /// 상품 삭제
  Future<void> deleteProduct(String id) async {
    try {
      _error = null;
      await _service.delete(id);
      await loadProducts();
    } catch (e) {
      _error = 'Failed to delete product: $e';
      notifyListeners();
    }
  }

  /// 카테고리별 필터
  List<Product> getFilteredProducts(String? categoryId) {
    if (categoryId == null) return _products;
    return _products.where((p) => p.categoryId == categoryId).toList();
  }
}
