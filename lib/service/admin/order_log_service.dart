import 'package:table_order/models/admin/order_log.dart';
import 'package:table_order/server/admin_server/order_log_server.dart';

class OrderService {
  final OrderServerStub _server = OrderServerStub();

  Future<List<OrderLog>> getOrderLogs() => _server.fetchOrderLogs();
}
