import 'package:flutter/material.dart';
import 'package:table_order/models/admin/product.dart';
import 'package:table_order/service/admin/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<Product> products = [];

  Future<void> loadProducts() async {
    products = await _service.getProducts();
    notifyListeners();
  }

  Future<void> addProduct(Product p) async {
    await _service.add(p);
    await loadProducts();
  }

  Future<void> updateProduct(String id, Product updated) async {
    await _service.update(id, updated);
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _service.delete(id);
    await loadProducts();
  }

  // 카테고리별 필터
  List<Product> getFilteredProducts(String? categoryId) {
    if (categoryId == null) return products;
    return products.where((p) => p.categoryId == categoryId).toList();
  }
}
