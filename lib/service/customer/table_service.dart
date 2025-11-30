import 'package:table_order/server/customer_server/table_server.dart';

class TableService {
  final TableServer _server = TableServer();

  Future<String?> getTableName(String tableId) async {
    return await _server.fetchTableName(tableId);
  }
}
