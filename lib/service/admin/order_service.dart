import 'package:table_order/server/admin_server/order_repository.dart';

/// 주문(Order) 도메인 Service
/// 주문 항목(OrderMenu)의 메뉴 상태 및 수량 관리 비즈니스 로직 처리
class OrderService {
  final OrderRepository _repository = OrderRepository();

  // ============= Orders(주문 항목) 관련 메서드 =============

  /// 주문의 메뉴 상태 업데이트
  Future<bool> updateMenuStatus({
    required String orderId,
    required int menuIndex,
    required String newStatus,
  }) async {
    return await _repository.updateMenuStatus(
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
    return await _repository.updateMenuQuantity(
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
    return await _repository.removeMenu(
      orderId: orderId,
      menuIndex: menuIndex,
    );
  }
}
