enum OrderStatus { empty, ordered }

class TableInfo {
  final String tableName;
  List<String> items;
  String? orderTime;
  int totalPrice;
  bool hasNewOrder;
  bool hasCallRequest;
  OrderStatus orderStatus;

  TableInfo({
    required this.tableName,
    this.items = const [],
    this.orderTime,
    this.totalPrice = 0,
    this.hasNewOrder = false,
    this.hasCallRequest = false,
    this.orderStatus = OrderStatus.empty,
  });
}
