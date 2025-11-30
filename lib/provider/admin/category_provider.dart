import 'package:flutter/material.dart';
import 'package:table_order/models/admin/category.dart';
import 'package:table_order/service/admin/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  int _selectedCategoryIndex = 0;
  int get selectedCategoryIndex => _selectedCategoryIndex;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _currentStoreId;

  /// 특정 가게의 카테고리 로드
  Future<void> loadCategories(String storeId) async {
    _isLoading = true;
    _error = null;
    _currentStoreId = storeId;
    notifyListeners();

    try {
      _categories = await _service.getCategories(storeId);
    } catch (e) {
      _error = 'Failed to load categories: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
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
      _error = null;
      await _service.addCategory(
        storeId: storeId,
        name: name,
        active: active,
        order: order,
      );
      await loadCategories(storeId);
    } catch (e) {
      _error = 'Failed to add category: $e';
      notifyListeners();
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
      _error = null;
      await _service.updateCategory(
        id: id,
        name: name,
        active: active,
        order: order,
      );
      if (_currentStoreId != null) {
        await loadCategories(_currentStoreId!);
      }
    } catch (e) {
      _error = 'Failed to update category: $e';
      notifyListeners();
    }
  }

  /// 카테고리 삭제
  Future<void> deleteCategory(String id) async {
    try {
      _error = null;
      await _service.deleteCategory(id);
      if (_currentStoreId != null) {
        await loadCategories(_currentStoreId!);
      }
    } catch (e) {
      _error = 'Failed to delete category: $e';
      notifyListeners();
    }
  }

  /// 카테고리 선택
  void selectCategory(int index) {
    _selectedCategoryIndex = index;
    notifyListeners();
  }
}
