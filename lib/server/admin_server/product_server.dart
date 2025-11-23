import 'dart:async';
import 'package:table_order/models/admin/product.dart';

class ProductServerStub {
  final List<Product> _products = [
    Product(
      id: "p1",
      name: "아메리카노",
      price: "5500",
      stock: 10,
      isSoldOut: false,
      isActive: true,
      description: "",
      categoryId: "c1",
    ),
    Product(
      id: "p2",
      name: "카페라떼",
      price: "6500",
      stock: 3,
      isSoldOut: true,
      isActive: true,
      description: "",
      categoryId: "c1",
    ),
    Product(
      id: "p3",
      name: "얼그레이 티",
      price: "6000",
      stock: 7,
      isSoldOut: false,
      isActive: true,
      description: "",
      categoryId: "c2",
    ),
  ];

  Future<List<Product>> fetchProducts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<Product>.from(_products);
  }

  Future<void> addProduct(Product p) async {
    _products.add(p);
    await Future.delayed(const Duration(milliseconds: 150));
  }

  Future<void> updateProduct(String id, Product updated) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) _products[index] = updated;
    await Future.delayed(const Duration(milliseconds: 150));
  }

  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    await Future.delayed(const Duration(milliseconds: 150));
  }
}
