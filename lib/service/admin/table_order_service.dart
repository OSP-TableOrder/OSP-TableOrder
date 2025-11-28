import 'package:table_order/server/admin_server/table_order_server.dart';
import 'package:table_order/models/admin/table_order_info.dart';

class TableOrderService {
  final TableOrderServerStub _server = TableOrderServerStub();

  Future<List<TableOrderInfo>> getTableOrders() async {
    return await _server.fetchTableOrders();
  }
}
