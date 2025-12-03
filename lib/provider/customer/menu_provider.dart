import 'package:flutter/foundation.dart';

import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/service/customer/menu_service.dart';

const String kUncategorizedCategoryId = '__uncategorized__';

class MenuProvider with ChangeNotifier {
  final MenuService _service = MenuService();

  List<Menu> _menus = [];
  bool _isLoading = false;
  String? _error;
  bool _hasAttemptedLoad = false; // 로드 시도 여부 추적

  List<Map<String, dynamic>> _groupedMenus = [];
  List<String?> _categoryIds = []; // 카테고리 ID 순서 유지 (null은 "기타")
  bool _hasUncategorizedMenus = false;

  List<Menu> get menus => _menus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasAttemptedLoad => _hasAttemptedLoad;

  List<Map<String, dynamic>> get groupedMenus => _groupedMenus;
  List<String?> get categoryIds => _categoryIds;
  bool get hasUncategorizedMenus => _hasUncategorizedMenus;

  List<dynamic> get displayList {
    final List<dynamic> list = [];
    final List<dynamic> noCategoryList = []; // 카테고리 없는 상품을 따로 저장

    for (final group in _groupedMenus) {
      final String? categoryId = group['categoryId'] as String?;
      final String? category = group['category'] as String?;
      final List<Menu> items = group['items'] as List<Menu>;

      // category가 없거나 빈 문자열이면 따로 저장
      if (category == null || category.isEmpty) {
        noCategoryList.addAll(items);
      } else {
        // 카테고리가 있으면 헤더와 함께 추가 (categoryId와 함께)
        list.add({'categoryId': categoryId, 'name': category});
        list.addAll(items);
      }
    }

    // 카테고리 없는 상품을 최하단에 추가
    if (noCategoryList.isNotEmpty) {
      list.add({'categoryId': kUncategorizedCategoryId, 'name': '기타'}); // 카테고리 없는 상품의 헤더
      list.addAll(noCategoryList);
    }

    return list;
  }

  // 특정 가게의 메뉴 목록을 불러오기
  Future<void> loadMenus(String storeId) async {
    _isLoading = true;
    _error = null;
    _hasAttemptedLoad = true; // 로드 시도 표시
    notifyListeners();

    try {
      _menus = await _service.getMenusByStoreId(storeId);
      _groupedMenus = await _service.getMenusGroupedByCategory(storeId);

      // categoryIds 추출
      final List<String?> ids = [];
      bool hasUncategorized = false;
      for (final group in _groupedMenus) {
        final String? category = group['category'] as String?;
        final String? categoryId = group['categoryId'] as String?;
        if (category == null || category.trim().isEmpty) {
          hasUncategorized = true;
          continue;
        }
        ids.add(categoryId);
      }
      if (hasUncategorized) {
        ids.add(kUncategorizedCategoryId);
      }
      _categoryIds = ids;
      _hasUncategorizedMenus = hasUncategorized;

      _error = null;
    } catch (e) {
      _error = 'Failed to load menus: $e';
      _menus = [];
      _groupedMenus = [];
      _categoryIds = [];
      _hasUncategorizedMenus = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 에러 상태 초기화
  void clearError() {
    _error = null;
    _hasAttemptedLoad = false; // 재시도 시 로드 시도 플래그 초기화
    notifyListeners();
  }
}
