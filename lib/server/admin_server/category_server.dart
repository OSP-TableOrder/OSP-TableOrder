import 'dart:async';
import 'package:table_order/models/admin/category.dart';

class CategoryServerStub {
  final List<Category> _categories = [
    Category(id: "c1", name: "COFFEE", active: true),
    Category(id: "c2", name: "TEA", active: false),
    Category(id: "c3", name: "BREAD", active: false),
  ];

  Future<List<Category>> fetchCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<Category>.from(_categories);
  }

  Future<void> addCategory(String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newId = "c${_categories.length + 1}";
    _categories.add(Category(id: newId, name: name, active: true));
  }

  Future<void> updateCategory(String id, String newName, bool active) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index].name = newName;
      _categories[index].active = active;
    }
  }

  Future<void> deleteCategory(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _categories.removeWhere((c) => c.id == id);
  }
}
