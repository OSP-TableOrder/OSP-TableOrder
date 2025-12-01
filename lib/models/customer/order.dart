import 'package:table_order/models/customer/order_menu.dart';
import 'package:table_order/models/customer/order_status.dart';

class Order {
  final String id;
  final String storeId; // Firestore 자동 생성 ID
  final String tableId;
  final int totalPrice;
  final List<OrderMenu> menus;
  final OrderStatus status; // 정산 상태: unpaid (미정산) 또는 paid (정산됨)
  final DateTime? createdAt; // 주문 생성 시간 (admin 페이지에서 주문 시간 표시용)

  const Order({
    required this.id,
    required this.storeId,
    required this.tableId,
    required this.totalPrice,
    required this.menus,
    this.status = OrderStatus.unpaid,
    this.createdAt,
  });

  Order copyWith({int? totalPrice, List<OrderMenu>? menus, OrderStatus? status, DateTime? createdAt}) {
    return Order(
      id: id,
      storeId: storeId,
      tableId: tableId,
      totalPrice: totalPrice ?? this.totalPrice,
      menus: menus ?? this.menus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
