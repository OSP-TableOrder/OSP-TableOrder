// TODO - 메뉴 모델과 연결
import '../../models/menu_item.dart';

class CartItem {
  final int id;
  // TODO - 메뉴 모델과 연결
  final MenuItem menuItem;
  final int quantity;

  CartItem({
    required this.id,
    // TODO - 메뉴 모델과 연결
    required this.menuItem,
    required this.quantity,
  });
}