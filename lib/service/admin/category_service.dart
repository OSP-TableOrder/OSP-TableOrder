import 'package:table_order/server/admin_server/category_server.dart';
import 'package:table_order/models/admin/category.dart';

class CategoryService {
  final CategoryServerStub _server = CategoryServerStub();

  Future<List<Category>> getCategories() => _server.fetchCategories();
  Future<void> addCategory(String name) => _server.addCategory(name);
  Future<void> updateCategory(String id, String newName, bool active) =>
      _server.updateCategory(id, newName, active);
  Future<void> deleteCategory(String id) => _server.deleteCategory(id);
}
