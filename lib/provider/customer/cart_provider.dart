import 'package:flutter/foundation.dart';
import 'package:table_order/models/customer/cart_item.dart';
import 'package:table_order/models/customer/menu.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  int get totalPrice {
    return _items.fold(
      0,
      (sum, item) => sum + (item.menu.price * item.quantity),
    );
  }

  bool get isEmpty => _items.isEmpty;

  /// Firestore 자동 생성 ID 스타일의 String ID 생성
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 장바구니에 메뉴 추가
  /// 같은 메뉴가 이미 있으면 수량을 증가시킴
  void addItem(Menu menu, int quantity) {
    final existingIndex = _items.indexWhere((item) => item.menu.id == menu.id);

    if (existingIndex != -1) {
      // 이미 있는 메뉴면 수량 증가
      final existingItem = _items[existingIndex];
      _items[existingIndex] = CartItem(
        id: existingItem.id,
        menu: existingItem.menu,
        quantity: existingItem.quantity + quantity,
      );
    } else {
      // 새로운 메뉴면 추가 (String id 생성)
      _items.add(CartItem(
        id: _generateId(),
        menu: menu,
        quantity: quantity,
      ));
    }

    notifyListeners();
  }

  /// 장바구니에서 아이템 제거
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// 장바구니 아이템 수량 변경
  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }

    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      _items[index] = CartItem(
        id: item.id,
        menu: item.menu,
        quantity: quantity,
      );
      notifyListeners();
    }
  }

  /// 장바구니 비우기
  void clear() {
    _items.clear();
    notifyListeners();
  }
}

