enum OrderStatus { empty, ordered }

/// 테이블의 각 주문을 나타내는 모델
class TableOrder {
  final String orderId;           // Firestore 주문 ID (receiptId)
  final String tableId;
  final String tableName;
  List<dynamic> items;            // 이 주문의 메뉴 항목들 (mutable)
  final String? orderTime;        // 주문 시간
  int totalPrice;                 // 이 주문의 총 가격 (mutable)
  bool hasNewOrder;               // 새로운 ORDERED 상태 항목 있음 (mutable)
  OrderStatus orderStatus;        // 주문 상태 (mutable)

  TableOrder({
    required this.orderId,
    required this.tableId,
    required this.tableName,
    this.items = const [],
    this.orderTime,
    this.totalPrice = 0,
    this.hasNewOrder = false,
    this.orderStatus = OrderStatus.empty,
  });
}

/// 테이블 정보 (여러 주문을 포함)
class TableOrderInfo {
  final String tableId;
  final String tableName;
  final List<TableOrder> orders;  // 이 테이블의 모든 주문들
  bool hasCallRequest;

  // 계산된 속성들
  int get totalPrice => orders.fold(0, (sum, order) => sum + order.totalPrice);
  bool get hasNewOrder => orders.any((order) => order.hasNewOrder);
  OrderStatus get orderStatus {
    if (orders.isEmpty) return OrderStatus.empty;
    return orders.any((order) => order.hasNewOrder)
        ? OrderStatus.ordered
        : OrderStatus.empty;
  }

  TableOrderInfo({
    required this.tableId,
    required this.tableName,
    this.orders = const [],
    this.hasCallRequest = false,
  });
}
