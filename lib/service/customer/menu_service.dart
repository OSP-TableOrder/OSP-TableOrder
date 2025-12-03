import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/server/customer_server/menu_server.dart';
import 'package:table_order/server/admin_server/category_server.dart';

class MenuService {
  final MenuServer _menuServer = MenuServer();
  final CategoryServer _categoryServer = CategoryServer();

  /// Store ID로 메뉴 조회
  Future<List<Menu>> getMenusByStoreId(String storeId) =>
      _menuServer.fetchMenusByStoreId(storeId);

  /// 메뉴 ID로 조회
  Future<Menu?> fetchMenuById(String menuId) => _menuServer.findById(menuId);

  /// 카테고리별로 그룹화된 메뉴 조회
  Future<List<Map<String, dynamic>>> getMenusGroupedByCategory(
    String storeId,
  ) async {
    // 1. 메뉴와 카테고리 동시 조회
    final menus = await getMenusByStoreId(storeId);
    final categories = await _categoryServer.fetchCategories(storeId);

    // 2. categoryId → Category 객체 맵 생성
    final categoryMap = {for (var c in categories) c.id: c};

    // 3. categoryId별로 메뉴 그룹화
    final Map<String?, List<Menu>> grouped = {};
    for (final menu in menus) {
      final key = menu.categoryId;
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(menu);
    }

    // 4. 카테고리 순서대로 정렬하여 결과 생성
    final List<Map<String, dynamic>> result = [];

    // 활성 카테고리만 order 순서대로
    final activeCategories = categories
        .where((c) => c.active && grouped.containsKey(c.id))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    for (final category in activeCategories) {
      result.add({
        'categoryId': category.id,
        'category': category.name,
        'items': grouped[category.id]!,
      });
    }

    // 카테고리가 없는 메뉴들 (null 또는 매칭 안 되는 경우)
    grouped.forEach((categoryId, items) {
      if (categoryId == null || !categoryMap.containsKey(categoryId)) {
        result.add({'categoryId': null, 'category': null, 'items': items});
      }
    });

    return result;
  }
}
