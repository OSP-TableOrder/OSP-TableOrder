import 'dart:async';
import 'package:table_order/models/admin/table_order_info.dart';

class TableOrderServerStub {
  final List<TableOrderInfo> fakeTableOrders = [
    TableOrderInfo(
      tableName: "1번",
      items: ["아메리카노", "카페라떼"],
      orderTime: "12:30",
      totalPrice: 12000,
      hasNewOrder: true,
      hasCallRequest: false,
      orderStatus: OrderStatus.ordered,
    ),
    TableOrderInfo(
      tableName: "2번",
      items: [],
      orderTime: null,
      totalPrice: 0,
      hasNewOrder: false,
      hasCallRequest: false,
      orderStatus: OrderStatus.empty,
    ),
    TableOrderInfo(
      tableName: "3번",
      items: [],
      orderTime: null,
      totalPrice: 0,
      hasNewOrder: false,
      hasCallRequest: true,
      orderStatus: OrderStatus.empty,
    ),
  ];

  Future<List<TableOrderInfo>> fetchTableOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return fakeTableOrders;
  }
}
