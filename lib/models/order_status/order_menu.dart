import 'package:table_order/models/order_status/order_menu_status.dart';

class OrderMenu {
  final int id;
  final OrderMenuStatus status;
  final int quantity;
  final int completedCount;
  // 메뉴 정보
  final String menuName;
  final int menuPrice;
  final String? menuDescription;
  final String? menuImageUrl;
  final bool? menuIsSoldOut;
  final bool? menuIsRecommended;

  const OrderMenu({
    required this.id,
    required this.status,
    required this.quantity,
    this.completedCount = 0,
    required this.menuName,
    required this.menuPrice,
    this.menuDescription,
    this.menuImageUrl,
    this.menuIsSoldOut,
    this.menuIsRecommended,
  });

  bool get isCancelable => status.isCancelable;

  OrderMenu copyWith({
    OrderMenuStatus? status,
    int? quantity,
    int? completedCount,
    String? menuName,
    int? menuPrice,
    String? menuDescription,
    String? menuImageUrl,
  }) {
    return OrderMenu(
      id: id,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      completedCount: completedCount ?? this.completedCount,
      menuName: menuName ?? this.menuName,
      menuPrice: menuPrice ?? this.menuPrice,
      menuDescription: menuDescription ?? this.menuDescription,
      menuImageUrl: menuImageUrl ?? this.menuImageUrl,
    );
  }
}
