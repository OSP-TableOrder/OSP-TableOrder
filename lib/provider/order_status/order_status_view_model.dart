import 'package:flutter/foundation.dart';

import '../../models/order_status/order.dart';
import '../../models/order_status/order_menu.dart';
import '../../models/order_status/order_menu_status.dart';

class OrderStatusViewModel extends ChangeNotifier {
  bool _loading = true;
  bool get loading => _loading;

  late Order _order;
  Order get order => _order;

  int get totalPrice => order.totalPrice;

  Future<void> loadInitial({required String receiptId}) async {
    _loading = true;
    notifyListeners();

    _order = Order(
      id: 438,
      totalPrice: 70000,
      menus: [
        OrderMenu(
          id: 11,
          status: OrderMenuStatus.ordered,
          quantity: 2,
          completedCount: 0,
          menuName: '불고기',
          menuPrice: 10000,
          menuDescription: '달콤짭잘 불고기, 단짠단짠으로 맛있게 드세요.',
          menuImageUrl:
              'https://i.namu.wiki/i/1fMv9BlDolXCcO2TlBW0zuV14FbmYAQf71zBGjY8RvtoP3x-zDBo0jiQxy4gdQ8ipfOqa9NNgGc5AOPVfRHlzQ.webp',
        ),
        OrderMenu(
          id: 12,
          status: OrderMenuStatus.cooking,
          quantity: 2,
          completedCount: 0,
          menuName: '한우 육회',
          menuPrice: 10000,
          menuDescription: '고소함 끝판왕, 술이 술술 들어가는 육회',
          menuImageUrl:
              'https://i.namu.wiki/i/1fMv9BlDolXCcO2TlBW0zuV14FbmYAQf71zBGjY8RvtoP3x-zDBo0jiQxy4gdQ8ipfOqa9NNgGc5AOPVfRHlzQ.webp',
        ),
        OrderMenu(
          id: 13,
          status: OrderMenuStatus.completed,
          quantity: 1,
          completedCount: 0,
          menuName: '닭목살구이',
          menuPrice: 15000,
          menuDescription: '쫄깃한 식감의 매콤달콤 양념, 우리 가게의 시그니처!',
          menuImageUrl:
              'https://i.namu.wiki/i/1fMv9BlDolXCcO2TlBW0zuV14FbmYAQf71zBGjY8RvtoP3x-zDBo0jiQxy4gdQ8ipfOqa9NNgGc5AOPVfRHlzQ.webp',
        ),
        OrderMenu(
          id: 13,
          status: OrderMenuStatus.canceled,
          quantity: 1,
          completedCount: 0,
          menuName: '닭날개',
          menuPrice: 15000,
          menuDescription: '너무 맛있어서 하늘을 윙윙 날아갈 것 같은 맛!',
          menuImageUrl:
              'https://i.namu.wiki/i/1fMv9BlDolXCcO2TlBW0zuV14FbmYAQf71zBGjY8RvtoP3x-zDBo0jiQxy4gdQ8ipfOqa9NNgGc5AOPVfRHlzQ.webp',
        ),
        OrderMenu(
          id: 14,
          status: OrderMenuStatus.cooking,
          quantity: 1,
          completedCount: 0,
          menuName: '광광우럭따',
          menuPrice: 15000,
          menuDescription: '넙치와 우럭을 한 접시에서 맛있게 즐기세요!',
          menuImageUrl:
              'https://i.namu.wiki/i/1fMv9BlDolXCcO2TlBW0zuV14FbmYAQf71zBGjY8RvtoP3x-zDBo0jiQxy4gdQ8ipfOqa9NNgGc5AOPVfRHlzQ.webp',
        ),
      ],
    );

    _loading = false;
    notifyListeners();
  }

  Future<void> refresh({required String receiptId}) async {
    notifyListeners();
  }

  Future<void> cancelMenu(int menuId) async {
    final idx = _order.menus.indexWhere((orderMenu) => orderMenu.id == menuId);
    if (idx == -1) return;

    final target = _order.menus[idx];
    if (!target.isCancelable) return;

    final updatedMenus = List<OrderMenu>.from(_order.menus);
    updatedMenus[idx] = target.copyWith(status: OrderMenuStatus.canceled);

    _order = _order.copyWith(menus: updatedMenus);
    notifyListeners();
  }
}
