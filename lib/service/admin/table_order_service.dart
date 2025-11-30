import 'package:table_order/server/admin_server/table_order_server.dart';
import 'package:table_order/models/admin/table_order_info.dart';

class TableOrderService {
  final TableOrderServer _server = TableOrderServer();

  /// 특정 가게의 미정산 주문 목록 조회
  Future<List<TableOrderInfo>> getUnpaidOrdersByStore(String storeId) async {
    return await _server.fetchUnpaidOrdersByStore(storeId);
  }

  /// 주문의 메뉴 상태 업데이트
  Future<bool> updateMenuStatus({
    required String orderId,
    required int menuIndex,
    required String newStatus,
  }) async {
    return await _server.updateMenuStatus(
      orderId: orderId,
      menuIndex: menuIndex,
      newStatus: newStatus,
    );
  }

  /// 주문의 메뉴 수량 업데이트
  Future<bool> updateMenuQuantity({
    required String orderId,
    required int menuIndex,
    required int newQuantity,
  }) async {
    return await _server.updateMenuQuantity(
      orderId: orderId,
      menuIndex: menuIndex,
      newQuantity: newQuantity,
    );
  }

  /// 주문의 메뉴 제거
  Future<bool> removeMenu({
    required String orderId,
    required int menuIndex,
  }) async {
    return await _server.removeMenu(
      orderId: orderId,
      menuIndex: menuIndex,
    );
  }

  /// 주문 상태 변경 (unpaid -> paid)
  Future<bool> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    return await _server.updateOrderStatus(
      orderId: orderId,
      newStatus: newStatus,
    );
  }

  /// 주문에 메뉴 추가 (전체 메뉴 객체 포함)
  Future<bool> addMenuToOrder({
    required String orderId,
    String? menuName,
    int? price,
    Map<String, dynamic>? menu,
    required int quantity,
  }) async {
    return await _server.addMenuToOrder(
      orderId: orderId,
      menuName: menuName,
      price: price,
      menu: menu,
      quantity: quantity,
    );
  }
}
