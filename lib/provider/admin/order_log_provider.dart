import 'package:flutter/material.dart';
import 'package:table_order/models/admin/order_log.dart';
import 'package:table_order/service/admin/order_log_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _service = OrderService();

  List<OrderLog> orderLogs = [];

  Future<void> loadOrderLogs() async {
    orderLogs = await _service.getOrderLogs();
    notifyListeners();
  }
}
