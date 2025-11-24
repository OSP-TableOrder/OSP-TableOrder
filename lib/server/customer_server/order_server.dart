import 'dart:async';
import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/models/customer/order.dart';
import 'package:table_order/models/customer/order_menu.dart';
import 'package:table_order/models/customer/order_menu_status.dart';

class OrderServerStub {
  final List<Order> _orders = [
    Order(
      id: "438",
      storeId: 1,
      totalPrice: 11000,
      menus: [
        OrderMenu(
          id: 1,
          status: OrderMenuStatus.ordered,
          quantity: 2,
          completedCount: 0,
          menu: Menu(
            id: 1,
            storeId: 1,
            name: "아메리카노",
            description: "kitCAFE 블렌드로 추출한 에스프레소를 부드럽게 즐길 수 있는 커피",
            imageUrl:
                "https://www.woorinews.co.kr/news/photo/202407/54820_58866_2943.png",
            price: 5500,
            isSoldOut: false,
            isRecommended: false,
          ),
        ),
      ],
    ),
  ];

  /// -----------------------------
  /// 주문 조회
  /// -----------------------------
  Future<Order?> findById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    int idx = _orders.indexWhere((order) => order.id == orderId);
    if (idx == -1) return null;

    return _orders[idx];
  }

  /// -----------------------------
  /// 메뉴 추가: 동일 메뉴면 수량 증가
  /// -----------------------------
  Future<Order?> addMenu(String orderId, OrderMenu newMenu) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) return null;

    final order = _orders[orderIndex];

    // 기존 메뉴 복사
    List<OrderMenu> updatedMenus = List<OrderMenu>.from(order.menus);

    // 1. 같은 메뉴가 기존에 있는지 확인
    final existingIndex =
        updatedMenus.indexWhere((m) => m.menu.id == newMenu.menu.id);

    if (existingIndex != -1) {
      // 2. 같은 메뉴가 있다 → quantity 증가
      final existing = updatedMenus[existingIndex];

      final updated = existing.copyWith(
        quantity: existing.quantity + newMenu.quantity,
      );

      updatedMenus[existingIndex] = updated;
    } else {
      // 3. 같은 메뉴가 없다 → 새로 추가
      updatedMenus.add(newMenu);
    }

    // 4. 총 금액 재계산 (취소된 메뉴 제외)
    final newTotalPrice = updatedMenus
        .where((m) => m.status != OrderMenuStatus.canceled)
        .fold<int>(0, (sum, m) => sum + (m.menu.price * m.quantity));

    // 5. Order 업데이트
    final updatedOrder = order.copyWith(
      menus: updatedMenus,
      totalPrice: newTotalPrice,
    );

    _orders[orderIndex] = updatedOrder;

    return updatedOrder;
  }

  /// -----------------------------
  /// 메뉴 취소: 상태를 canceled 로 변경
  /// -----------------------------
  Future<Order?> cancelMenu(String orderId, int menuId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) return null;

    final order = _orders[orderIndex];

    final menuIndex = order.menus.indexWhere((m) => m.id == menuId);
    if (menuIndex == -1) return order;

    final target = order.menus[menuIndex];

    // 취소 불가능한 상태면 그대로 반환
    if (!target.isCancelable) {
      return order;
    }

    // 상태를 canceled 로 변경
    final updatedMenu = target.copyWith(status: OrderMenuStatus.canceled);

    final updatedMenus = List<OrderMenu>.from(order.menus);
    updatedMenus[menuIndex] = updatedMenu;

    // 총 금액 재계산
    final newTotalPrice = updatedMenus
        .where((m) => m.status != OrderMenuStatus.canceled)
        .fold(0, (sum, m) => sum + (m.menu.price * m.quantity));

    final updatedOrder = order.copyWith(
      menus: updatedMenus,
      totalPrice: newTotalPrice,
    );

    _orders[orderIndex] = updatedOrder;
    return updatedOrder;
  }
}
