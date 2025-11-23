import 'package:table_order/server/admin_server/table_server.dart';
import 'package:table_order/models/admin/table_info.dart';

class TableService {
  final TableServerStub _server = TableServerStub();

  Future<List<TableInfo>> getTableOrders() async {
    return await _server.fetchTableOrders();
  }
}
