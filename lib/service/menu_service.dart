import 'package:table_order/models/menu.dart';
import 'package:table_order/server/user_server.dart';

class MenuService {
  // Mock API
  final Server _server = Server();

  // 전체 메뉴 목록 가져오기
  Future<List<Menu>> fetchAllMenus() => _server.getAllMenus();

  // 특정 가게의 메뉴 목록 가져오기
  Future<List<Menu>> fetchMenusByStoreId(int storeId) => _server.getMenusByStoreId(storeId);

  // ID로 특정 메뉴 찾기
  Future<Menu?> fetchMenuById(int menuId) => _server.getMenuById(menuId);
}
