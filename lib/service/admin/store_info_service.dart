import 'package:table_order/models/admin/store_info.dart';
import 'package:table_order/server/admin_server/store_info_server.dart';

class StoreInfoService {
  final StoreInfoServer _server = StoreInfoServer();

  Future<StoreInfoModel> getStoreInfo(String storeId) async {
    return await _server.fetchStoreInfo(storeId);
  }

  Future<void> updateStoreInfo({
    required String storeId,
    required String name,
    required String notice,
  }) async {
    await _server.updateStoreInfo(
      storeId: storeId,
      name: name,
      notice: notice,
    );
  }
}
