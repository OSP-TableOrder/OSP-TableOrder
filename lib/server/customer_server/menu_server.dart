import 'dart:async';
import 'package:table_order/models/customer/menu.dart';

class MenuServerStub {
  final List<Menu> _menus = [
    Menu(
      id: 1,
      storeId: 1,
      category: "커피",
      name: "아메리카노",
      description: "kitCAFE 블렌드로 추출한 에스프레소를 부드럽게 즐길 수 있는 커피",
      imageUrl:
          "https://www.woorinews.co.kr/news/photo/202407/54820_58866_2943.png",
      price: 5500,
      isSoldOut: false,
      isRecommended: false,
    ),
    Menu(
      id: 2,
      storeId: 1,
      category: "커피",
      name: "카페라떼",
      description: "에스프레소와 부드러운 우유의 조화가 매력적인 커피",
      imageUrl:
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ_EkBajqRgceeStCsT_N3Z1z9uo7HZyzCocg&s",
      price: 6500,
      isSoldOut: true,
      isRecommended: false,
    ),
    Menu(
      id: 3,
      storeId: 1,
      category: "티",
      name: "얼그레이 티",
      description: "달콤쌉싸름한 자몽과 얼그레이 티가 만나 향기롭고 달콤하게 즐길 수 있는 티 블렌딩 음료",
      imageUrl:
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcThd8yCBZNOz2gkEwpY28Ae9mF7phVqTIFZiA&s",
      price: 6000,
      isSoldOut: false,
      isRecommended: false,
    ),
  ];

  Future<List<Menu>> fetchMenusByStoreId(int storeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _menus.where((menu) => menu.storeId == storeId).toList();
  }

  Future<Menu?> findById(int menuId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    int idx = _menus.indexWhere((menu) => menu.id == menuId);
    if (idx == -1) return null;

    return _menus[idx];
  }
}
