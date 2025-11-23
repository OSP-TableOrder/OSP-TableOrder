import 'package:table_order/models/customer/store.dart';
import 'package:table_order/server/customer_server/store_server.dart';

class StoreService {
  static final StoreServerStub _server = StoreServerStub();

  Future<List<Store>> getStores() async {
    return await _server.fetchStores();
  }

  Future<Store?> getStore(int id) async {
    return await _server.findById(id);
  }
}
