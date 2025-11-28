import 'package:flutter/material.dart';
import 'package:table_order/models/admin/table_order_info.dart';
import 'package:table_order/service/admin/table_order_service.dart';

class TableOrderProvider extends ChangeNotifier {
  final TableOrderService _service = TableOrderService();

  List<TableOrderInfo> tables = [];

  Future<void> loadTables() async {
    tables = await _service.getTableOrders();
    notifyListeners();
  }

  // 신규 주문 확인
  void checkNewOrder(int index) {
    tables[index].hasNewOrder = false;
    notifyListeners();
  }

  // 직원 호출 확인
  void checkCallRequest(int index) {
    tables[index].hasCallRequest = false;
    notifyListeners();
  }
}
