import 'package:flutter/foundation.dart';
import 'package:table_order/models/menu.dart';
import 'package:table_order/service/menu_service.dart';

class MenuProvider with ChangeNotifier {
  final MenuService _menuService = MenuService();
  List<Menu> _menus = [];
  bool _isLoading = false;

  List<Menu> get menus => _menus;
  bool get isLoading => _isLoading;

  // 특정 가게의 메뉴 목록을 불러오기
  Future<void> loadMenus(int storeId) async {
    _isLoading = true;
    notifyListeners();

    _menus = await _menuService.fetchMenusByStoreId(storeId);

    _isLoading = false;
    notifyListeners();
  }
}
