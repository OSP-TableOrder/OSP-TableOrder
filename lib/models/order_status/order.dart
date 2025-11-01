import '../../models/order_status/order_menu.dart';

class Order {
  final int id;
  final int totalPrice;
  final List<OrderMenu> menus;

  const Order({
    required this.id,
    required this.totalPrice,
    required this.menus,
  });

  Order copyWith({int? totalPrice, List<OrderMenu>? menus}) {
    return Order(
      id: id,
      totalPrice: totalPrice ?? this.totalPrice,
      menus: menus ?? this.menus,
    );
  }
}
