import 'package:table_order/models/customer/order.dart';
import 'package:table_order/models/customer/order_menu.dart';
import 'package:table_order/server/customer_server/order_server.dart';

class OrderService {
  final OrderServer _server = OrderServer();

  /// Receipt 생성 (새로운 영수증 생성 또는 기존 미정산 영수증 조회)
  Future<Order> createReceipt({
    required String storeId,
    required String tableId,
  }) async {
    final receipt = await _server.createOrder(
      storeId: storeId,
      tableId: tableId,
    );

    if (receipt == null) {
      throw Exception("영수증 생성에 실패했습니다.");
    }

    return receipt;
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

  /// Order 생성 (기존 Receipt에 새로운 Order 추가)
  /// 첫 주문이든 추가 주문이든 항상 호출됨
  Future<Order> createOrder({
    required String receiptId,
    required String storeId,
    required String tableId,
  }) async {
    final order = await _server.createOrderForReceipt(
      receiptId: receiptId,
      storeId: storeId,
      tableId: tableId,
    );

    if (order == null) {
      throw Exception("주문 생성에 실패했습니다.");
    }

    return order;
  }
}
