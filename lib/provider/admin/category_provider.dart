import 'package:flutter/material.dart';
import 'package:table_order/models/admin/category.dart';
import 'package:table_order/service/admin/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  List<Category> categories = [];
  int selectedCategoryIndex = 0;

  Future<void> loadCategories() async {
    categories = await _service.getCategories();
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    await _service.addCategory(name);
    await loadCategories();
  }

  Future<void> updateCategory(String id, String newName, bool active) async {
    await _service.updateCategory(id, newName, active);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _service.deleteCategory(id);
    await loadCategories();
  }

  void selectCategory(int index) {
    selectedCategoryIndex = index;
    notifyListeners();
  }
}
