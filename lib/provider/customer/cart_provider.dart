import 'package:flutter/foundation.dart';
import 'package:table_order/models/customer/cart_item.dart';
import 'package:table_order/models/customer/menu.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  // 외부에서 리스트를 직접 수정하지 못하도록 unmodifiable로 반환
  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  // 장바구니 총 금액 계산 (아이템 수량 변경 시 자동 반영됨)
  int get totalPrice {
    return _items.fold(
      0,
      (sum, item) => sum + (item.menu.price * item.quantity),
    );
  }

  bool get isEmpty => _items.isEmpty;

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 장바구니에 메뉴 추가
  void addItem(Menu menu, int quantity) {
    final existingIndex = _items.indexWhere((item) => item.menu.id == menu.id);

    if (existingIndex != -1) {
      final existingItem = _items[existingIndex];
      _items[existingIndex] = CartItem(
        id: existingItem.id,
        menu: existingItem.menu,
        quantity: existingItem.quantity + quantity,
      );
    } else {
      _items.add(CartItem(id: _generateId(), menu: menu, quantity: quantity));
    }

    notifyListeners();
  }

  /// 장바구니에서 아이템 제거
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// 수량 1 증가
  void incrementQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      _items[index] = CartItem(
        id: item.id,
        menu: item.menu,
        quantity: item.quantity + 1,
      );
      notifyListeners(); // UI 업데이트 및 총액 재계산
    }
  }

  /// 수량 1 감소 (최소 1개 유지)
  void decrementQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      // 1개보다 클 때만 감소
      if (item.quantity > 1) {
        _items[index] = CartItem(
          id: item.id,
          menu: item.menu,
          quantity: item.quantity - 1,
        );
        notifyListeners(); // UI 업데이트 및 총액 재계산
      }
    }
  }

  /// 특정 수량으로 직접 업데이트
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
