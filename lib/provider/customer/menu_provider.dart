import 'package:flutter/foundation.dart';

import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/service/customer/menu_service.dart';

class MenuProvider with ChangeNotifier {
  final MenuService _service = MenuService();

  List<Menu> _menus = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> _groupedMenus = [];

  List<Menu> get menus => _menus;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> get groupedMenus => _groupedMenus;

  List<dynamic> get displayList {
    final List<dynamic> list = [];

    for (final group in _groupedMenus) {
      final String? category = group['category'] as String?;
      final List<Menu> items = group['items'] as List<Menu>;

      // category가 null이면 헤더를 추가하지 않고 메뉴만 출력
      if (category != null && category.isNotEmpty) {
        list.add(category);
      }

      list.addAll(items);
    }

    return list;
  }

  // 특정 가게의 메뉴 목록을 불러오기
  Future<void> loadMenus(int storeId) async {
    _isLoading = true;
    notifyListeners();

    _menus = await _service.getMenusByStoreId(storeId);

    _groupedMenus = await _service.getMenusGroupedByCategory(storeId);

    _isLoading = false;
    notifyListeners();
  }
}
