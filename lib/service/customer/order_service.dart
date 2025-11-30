import 'package:table_order/models/customer/order.dart';
import 'package:table_order/models/customer/order_menu.dart';
import 'package:table_order/server/customer_server/order_server.dart';

class OrderService {
  final OrderServerStub _server = OrderServerStub();

  /// 새로운 주문 생성
  Future<Order> createOrder({
    required String storeId,
    required String tableId,
  }) async {
    final order = await _server.createOrder(
      storeId: storeId,
      tableId: tableId,
    );

    if (order == null) {
      throw Exception("주문 생성에 실패했습니다.");
    }

    return order;
  }

  /// 테이블의 미정산 주문 조회 (QR 코드 스캔 시 기존 주문 확인)
  Future<Order?> findUnpaidOrderByTable({
    required String storeId,
    required String tableId,
  }) async {
    return await _server.findUnpaidOrderByTable(
      storeId: storeId,
      tableId: tableId,
    );
  }

  Future<Order> getOrder(String id) async {
    final order = await _server.findById(id);

    if (order == null) {
      throw Exception("주문을 찾을 수 없습니다.");
    }

    return order;
  }

  Future<Order> addMenu({
    required String orderId,
    required OrderMenu menu,
  }) async {
    final order = await _server.addMenu(orderId, menu);
    if (order == null) {
      throw Exception('주문을 찾을 수 없습니다. (id: $orderId)');
    }
    return order;
  }

  Future<Order> cancelMenu({
    required String orderId,
    required String menuId,
  }) async {
    final order = await _server.cancelMenu(orderId, menuId);
    if (order == null) {
      throw Exception("주문을 찾을 수 없습니다.");
    }
    return order;
  }
}
