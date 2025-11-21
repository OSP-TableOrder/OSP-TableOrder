import 'package:table_order/models/menu.dart';  

class CartItem {
  final int id;
  final Menu menu;
  final int quantity;

  CartItem({
    required this.id,
    required this.menu,
    required this.quantity,
  });
}