import 'package:table_order/models/customer/order_menu.dart';

class Order {
  final String id;
  final int storeId;
  final int totalPrice;
  final List<OrderMenu> menus;

  const Order({
    required this.id,
    required this.storeId,
    required this.totalPrice,
    required this.menus,
  });

  Order copyWith({int? totalPrice, List<OrderMenu>? menus}) {
    return Order(
      id: id,
      storeId: storeId,
      totalPrice: totalPrice ?? this.totalPrice,
      menus: menus ?? this.menus,
    );
  }
}
