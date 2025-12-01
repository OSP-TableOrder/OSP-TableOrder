import 'package:table_order/models/customer/menu.dart';

class CartItem {
  final String id;
  final Menu menu;
  final int quantity;

  CartItem({required this.id, required this.menu, required this.quantity});
}
