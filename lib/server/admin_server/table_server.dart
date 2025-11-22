import 'dart:async';
import 'package:table_order/models/admin/table_info.dart';

class TableServerStub {
  final List<TableInfo> fakeTableOrders = [
    TableInfo(
      tableName: "1번",
      items: ["아메리카노", "카페라떼"],
      orderTime: "12:30",
      totalPrice: 12000,
      hasNewOrder: true,
      hasCallRequest: false,
      orderStatus: OrderStatus.ordered,
    ),
    TableInfo(
      tableName: "2번",
      items: [],
      orderTime: null,
      totalPrice: 0,
      hasNewOrder: false,
      hasCallRequest: false,
      orderStatus: OrderStatus.empty,
    ),
    TableInfo(
      tableName: "3번",
      items: [],
      orderTime: null,
      totalPrice: 0,
      hasNewOrder: false,
      hasCallRequest: true,
      orderStatus: OrderStatus.empty,
    ),
  ];

  Future<List<TableInfo>> fetchTableOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return fakeTableOrders;
  }
}
