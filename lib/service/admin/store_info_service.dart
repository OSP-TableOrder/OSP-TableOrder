import 'package:table_order/models/admin/store_info.dart';
import 'package:table_order/server/admin_server/store_info_server.dart';

class StoreInfoService {
  final StoreInfoServerStub _serverStub = StoreInfoServerStub();

  Future<StoreInfoModel> getStoreInfo() async {
    return await _serverStub.fetchStoreInfo();
  }

  Future<void> updateStoreInfo(String name, String notice) async {
    await _serverStub.updateStoreInfo(name, notice);
  }
}
