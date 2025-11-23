import 'dart:async';
import 'package:table_order/models/admin/order_log.dart';

class OrderServerStub {
  final List<OrderLog> _logs = [
    OrderLog(tableName: "1번 테이블", orderSummary: "아메리카노 2개", time: "14:18"),
    OrderLog(tableName: "4번 테이블", orderSummary: "카페라떼 1개", time: "14:19"),
  ];

  Future<List<OrderLog>> fetchOrderLogs() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<OrderLog>.from(_logs);
  }
}
