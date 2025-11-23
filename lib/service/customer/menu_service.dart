import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/server/customer_server/menu_server.dart';

class MenuService {
  final MenuServerStub _server = MenuServerStub();

  Future<List<Menu>> getMenusByStoreId(int menuId) =>
      _server.fetchMenusByStoreId(menuId);

  Future<Menu?> fetchMenuById(int menuId) => _server.findById(menuId);

  Future<List<Map<String, dynamic>>> getMenusGroupedByCategory(
    int storeId,
  ) async {
    final menus = await getMenusByStoreId(storeId);

    final Map<String?, List<Menu>> grouped = {};
    for (final menu in menus) {
      final key = menu.category;
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(menu);
    }

    final List<Map<String, dynamic>> result = [];
    grouped.forEach((category, items) {
      result.add({'category': category, 'items': items});
    });

    return result;
  }
}
