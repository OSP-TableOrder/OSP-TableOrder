import 'package:table_order/models/menu.dart';
import 'package:table_order/models/order_status/order_menu_status.dart';

class OrderMenu {
  final int id;
  final OrderMenuStatus status;
  final int quantity;
  final int completedCount;
  // 메뉴 정보
  final Menu menu;

  const OrderMenu({
    required this.id,
    required this.status,
    required this.quantity,
    this.completedCount = 0,
    required this.menu,
  });

  bool get isCancelable => status.isCancelable;

  OrderMenu copyWith({
    OrderMenuStatus? status,
    int? quantity,
    int? completedCount,
    Menu? menu,
  }) {
    return OrderMenu(
      id: id,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      completedCount: completedCount ?? this.completedCount,
      menu: menu ?? this.menu,
    );
  }
}
