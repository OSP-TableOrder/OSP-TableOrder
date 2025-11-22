import 'package:flutter/foundation.dart';

import 'package:table_order/models/menu.dart';
import 'package:table_order/models/order_status/order.dart';
import 'package:table_order/models/order_status/order_menu.dart';
import 'package:table_order/models/order_status/order_menu_status.dart';

class OrderStatusViewModel extends ChangeNotifier {
  bool _loading = true;
  bool get loading => _loading;

  String? _receiptId;

  Order _order = Order(id: 0, totalPrice: 0, menus: []);
  Order get order => _order;

  int get totalPrice => order.totalPrice;

  Future<void> loadInitial({required String receiptId}) async {
    _loading = true;
    notifyListeners();

    _receiptId = receiptId;

    _order = Order(
      id: 438,
      totalPrice: 70000,
      menus: [
        OrderMenu(
          id: 11,
          status: OrderMenuStatus.ordered,
          quantity: 2,
          completedCount: 0,
          menu: Menu(
            id: 1,
            storeId: 1,
            name: '불고기',
            price: 10000,
            description: '달콤짭잘 불고기, 단짠단짠으로 맛있게 드세요.',
            imageUrl:
                'https://i.namu.wiki/i/1fMv9BlDolXCcO2TlBW0zuV14FbmYAQf71zBGjY8RvtoP3x-zDBo0jiQxy4gdQ8ipfOqa9NNgGc5AOPVfRHlzQ.webp',
            isSoldOut: false,
            isRecommended: true,
          ),
        ),
        OrderMenu(
          id: 12,
          status: OrderMenuStatus.cooking,
          quantity: 2,
          completedCount: 0,
          menu: Menu(
            id: 2,
            storeId: 1,
            name: '한우 육회',
            price: 10000,
            description: '고소함 끝판왕, 술이 술술 들어가는 육회',
            imageUrl:
                'https://recipe1.ezmember.co.kr/cache/recipe/2023/04/04/441e7047cbb92b5af604f242096d202a1.jpg',
            isSoldOut: false,
            isRecommended: true,
          ),
        ),
        OrderMenu(
          id: 13,
          status: OrderMenuStatus.completed,
          quantity: 1,
          completedCount: 0,
          menu: Menu(
            id: 3,
            storeId: 1,
            name: '닭목살구이',
            price: 15000,
            description: '쫄깃한 식감에 매콤달콤 양념, 우리 가게의 시그니처!',
            imageUrl:
                'https://sitem.ssgcdn.com/51/84/43/item/1000570438451_i1_750.jpg',
            isSoldOut: false,
            isRecommended: true,
          ),
        ),
        OrderMenu(
          id: 14,
          status: OrderMenuStatus.canceled,
          quantity: 1,
          completedCount: 0,
          menu: Menu(
            id: 4,
            storeId: 1,
            name: '닭날개',
            price: 15000,
            description: '너무 맛있어서 하늘을 윙윙 날아갈 것 같은 맛!',
            imageUrl:
                'https://semie.cooking/image/contents/recipe/qg/cc/uydikjnw/121619443kefn.jpg',
            isSoldOut: false,
            isRecommended: true,
          ),
        ),
        OrderMenu(
          id: 15,
          status: OrderMenuStatus.cooking,
          quantity: 1,
          completedCount: 0,
          menu: Menu(
            id: 5,
            storeId: 1,
            name: '광광우럭따',
            price: 15000,
            description: '넙치와 우럭을 한 접시에서 맛있게 즐기세요!',
            imageUrl:
                'https://gurimarket.co.kr/data/item/1481704220/thumb-_DSC0116_1090x700.jpg',
            isSoldOut: false,
            isRecommended: true,
          ),
        ),
      ],
    );

    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_receiptId == null) return;
    notifyListeners();
  }

  Future<void> cancelMenu(int menuId) async {
    final idx = _order.menus.indexWhere((orderMenu) => orderMenu.id == menuId);
    if (idx == -1) return;

    final target = _order.menus[idx];
    if (!target.isCancelable) return;

    final updatedMenus = List<OrderMenu>.from(_order.menus);
    updatedMenus[idx] = target.copyWith(status: OrderMenuStatus.canceled);

    final newTotalPrice = updatedMenus
        .where((menu) => menu.status != OrderMenuStatus.canceled)
        .fold<int>(0, (sum, menu) => sum + (menu.menu.price * menu.quantity));
    _order = _order.copyWith(menus: updatedMenus, totalPrice: newTotalPrice);

    notifyListeners();
  }
}
