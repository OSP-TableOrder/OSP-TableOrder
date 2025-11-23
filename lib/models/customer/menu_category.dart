import 'package:table_order/models/customer/menu.dart';

class MenuCategory {
  final int id;
  final String name;
  final List<Menu> items;

  MenuCategory({required this.id, required this.name, required this.items});
}
