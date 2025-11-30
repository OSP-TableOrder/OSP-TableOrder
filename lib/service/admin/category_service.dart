import 'package:table_order/server/admin_server/category_server.dart';
import 'package:table_order/models/admin/category.dart';

class CategoryService {
  final CategoryServer _server = CategoryServer();

  /// 특정 가게의 카테고리 조회
  Future<List<Category>> getCategories(String storeId) =>
      _server.fetchCategories(storeId);

  /// 카테고리 추가
  Future<void> addCategory({
    required String storeId,
    required String name,
    bool active = true,
    int order = 0,
  }) =>
      _server.addCategory(
        storeId: storeId,
        name: name,
        active: active,
        order: order,
      );

  /// 카테고리 수정
  Future<void> updateCategory({
    required String id,
    required String name,
    required bool active,
    required int order,
  }) =>
      _server.updateCategory(
        id: id,
        name: name,
        active: active,
        order: order,
      );

  /// 카테고리 삭제
  Future<void> deleteCategory(String id) => _server.deleteCategory(id);
}
