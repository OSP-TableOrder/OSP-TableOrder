import 'package:flutter/foundation.dart';

import 'package:table_order/models/customer/order.dart';
import 'package:table_order/models/customer/order_menu.dart';
import 'package:table_order/service/customer/order_service.dart';

class OrderStatusViewModel extends ChangeNotifier {
  final OrderService _service = OrderService();

  bool _loading = true;
  bool get loading => _loading;

  String? _receiptId;
  String? get receiptId => _receiptId;

  Order _order = Order(id: "0", storeId: 0, totalPrice: 0, menus: []);
  Order get order => _order;

  int get totalPrice => order.totalPrice;

  /// receiptId 설정 (QR 코드로 받은 아이디를 저장)
  void setReceiptId(String receiptId) {
    _receiptId = receiptId;
    notifyListeners();
  }

  Future<void> loadInitial({required String receiptId}) async {
    _loading = true;
    notifyListeners();

    _receiptId = receiptId;

    try {
      _order = await _service.getOrder(receiptId);
    } catch (e) {
      _order = const Order(id: "0", storeId: 0, totalPrice: 0, menus: []);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_receiptId == null) return;

    try {
      final latest = await _service.getOrder(_receiptId!);
      _order = latest;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addMenu(OrderMenu menu) async {
    if (_receiptId == null) return;

    try {
      await _service.addMenu(orderId: _receiptId!, menu: menu);

      // 서버 변경사항 반영
      await refresh();
    } catch (_) {}
  }

  Future<void> cancelMenu(int menuId) async {
    if (_receiptId == null) return;

    try {
      await _service.cancelMenu(orderId: _receiptId!, menuId: menuId);

      // 최신 상태 갱신
      await refresh();
    } catch (_) {}
  }
}
