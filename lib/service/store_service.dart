import 'package:table_order/models/store.dart';
import 'package:table_order/server/user_server.dart';

class StoreService {
  // Mock API
  final Server _server = Server();

  // 전체 가게 목록 가져오기
  Future<List<Store>> fetchAllStores() => _server.getAllStores();

  // ID로 특정 가게 찾기
  Future<Store?> fetchStoreById(int id) => _server.getStoreById(id);
}
