import 'package:flutter/material.dart';
import 'package:table_order/models/admin/order_log.dart';
import 'package:table_order/models/admin/table_order_info.dart';
import 'package:table_order/service/admin/order_log_service.dart';

class OrderLogProvider extends ChangeNotifier {
  final OrderLogService _service = OrderLogService();

  List<OrderLog> orderLogs = [];

  void loadOrderLogs(List<TableOrderInfo> tables) {
    orderLogs = _service.buildOrderLogs(tables);
    notifyListeners();
  }
}
