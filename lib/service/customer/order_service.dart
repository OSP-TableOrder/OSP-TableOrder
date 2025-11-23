import 'package:table_order/models/customer/order.dart';
import 'package:table_order/server/customer_server/order_server.dart';

class OrderService {
  final OrderServerStub _server = OrderServerStub();

  Future<Order> getOrder(String id) async {
    final order = await _server.findById(id);

    if (order == null) {
      throw Exception("주문을 찾을 수 없습니다.");
    }

    return order;
  }

  Future<Order> cancelMenu({
    required String orderId,
    required int menuId,
  }) async {
    final order = await _server.cancelMenu(orderId, menuId);
    if (order == null) {
      throw Exception("주문을 찾을 수 없습니다.");
    }
    return order;
  }
}
