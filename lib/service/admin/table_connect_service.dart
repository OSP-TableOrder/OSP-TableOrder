import 'package:table_order/models/admin/table_model.dart';
import 'package:table_order/server/admin_server/table_connect_server.dart';

class TableConnectService {
  final TableConnectServerStub _serverStub = TableConnectServerStub();

  Future<List<TableModel>> getTables() async {
    return await _serverStub.fetchTables();
  }

  Future<void> addTable(String name) async {
    await _serverStub.addTable(name);
  }

  Future<void> deleteTable(String id) async {
    await _serverStub.deleteTable(id);
  }
}
