import 'package:table_order/models/menu.dart';

class MenuCategory {
  final int id;
  final String name;
  final List<Menu> items;

  MenuCategory({
    required this.id,
    required this.name,
    required this.items
  });
}
