import 'package:table_order/models/menu.dart';

class MenuCategory {
  final String name;
  final List<Menu> items;

  MenuCategory({
    required this.name, 
    required this.items
  });
}
