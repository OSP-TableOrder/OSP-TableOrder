import 'package:table_order/models/admin/table_model.dart';
import 'package:table_order/server/admin_server/table_connect_server.dart';

class TableConnectService {
  final TableConnectServer _server = TableConnectServer();

  Future<List<TableModel>> getTables(String storeId) async {
    return await _server.fetchTables(storeId);
  }

  Future<void> addTable({
    required String storeId,
    required String name,
  }) async {
    await _server.addTable(storeId: storeId, name: name);
  }

  Future<void> updateTable({
    required String id,
    required String name,
  }) async {
    await _server.updateTable(id: id, name: name);
  }

  Future<void> deleteTable(String id) async {
    await _server.deleteTable(id);
  }
}
