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

  Future<Order?> findById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    int idx = _orders.indexWhere((order) => order.id == orderId);
    if (idx == -1) return null;

    return _orders[idx];
  }

  Future<Order?> addMenu(String orderId, OrderMenu newMenu) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) return null;

    final order = _orders[orderIndex];

    List<OrderMenu> updatedMenus = List<OrderMenu>.from(order.menus);

    updatedMenus.add(newMenu);

    final newTotalPrice = updatedMenus
        .where((m) => m.status != OrderMenuStatus.canceled)
        .fold<int>(0, (sum, m) => sum + (m.menu.price * m.quantity));

    final updatedOrder = order.copyWith(
      menus: updatedMenus,
      totalPrice: newTotalPrice,
    );

    _orders[orderIndex] = updatedOrder;

    return updatedOrder;
  }

  Future<Order?> cancelMenu(String orderId, int menuId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) return null;

    final order = _orders[orderIndex];

    final menuIndex = order.menus.indexWhere((m) => m.id == menuId);
    if (menuIndex == -1) return order; // 해당 메뉴 없으면 그냥 기존 주문 반환

    final target = order.menus[menuIndex];
    if (!target.isCancelable) {
      return order; // 취소 불가 상태면 변경 없이 반환
    }

    // 메뉴 상태 변경
    final updatedMenus = List<OrderMenu>.from(order.menus);
    updatedMenus[menuIndex] = target.copyWith(status: OrderMenuStatus.canceled);

    // 총 금액 재계산 (취소된 메뉴 제외)
    final newTotalPrice = updatedMenus
        .where((m) => m.status != OrderMenuStatus.canceled)
        .fold<int>(0, (sum, m) => sum + (m.menu.price * m.quantity));

    final updatedOrder = order.copyWith(
      menus: updatedMenus,
      totalPrice: newTotalPrice,
    );

    _orders[orderIndex] = updatedOrder;

    return updatedOrder;
  }
}
