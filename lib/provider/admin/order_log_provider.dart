import 'package:flutter/material.dart';
import 'package:table_order/models/admin/order_log.dart';
import 'package:table_order/service/admin/order_log_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _service = OrderService();
  List<OrderLog> orderLogs = [];

  // 읽지 않은 알림(빨간 점) 상태
  bool _hasUnreadAlert = false;
  bool get hasUnreadAlert => _hasUnreadAlert;

  Future<void> loadOrderLogs() async {
    // DB에서 최신 로그를 가져옴
    final newLogs = await _service.getOrderLogs();

    // 기존보다 개수가 늘어났다면 새로운 주문이 들어온 것으로 간주
    if (newLogs.length > orderLogs.length) {
      _hasUnreadAlert = true;
    }

    orderLogs = newLogs;
    notifyListeners();
  }

  // 알림 확인 처리 (빨간 점 끄기)
  void markAsRead() {
    _hasUnreadAlert = false;
    notifyListeners();
  }
}
