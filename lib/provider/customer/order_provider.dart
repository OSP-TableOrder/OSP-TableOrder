import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import 'package:table_order/models/customer/order.dart';
import 'package:table_order/models/customer/order_menu.dart';
import 'package:table_order/models/common/order_menu_status.dart';
import 'package:table_order/service/customer/order_service.dart';

class OrderStatusViewModel extends ChangeNotifier {
  final OrderService _service = OrderService();

  bool _loading = true;
  bool get loading => _loading;

  String? _receiptId;
  String? get receiptId => _receiptId;

  String? _orderId;  // Orders 컬렉션의 Order ID (정규화된 구조용)
  String? get orderId => _orderId;

  Order _order = const Order(
    id: "0",
    storeId: "",
    tableId: "",
    totalPrice: 0,
    menus: [],
  );
  Order get order => _order;

  int get totalPrice => order.totalPrice;

  /// receiptId 설정 (QR 코드로 받은 아이디를 저장)
  void setReceiptId(String receiptId) {
    _receiptId = receiptId;
    notifyListeners();
  }

  /// 정산 완료 후 호출: 다음 주문을 위해 receiptId 초기화
  void clearReceipt() {
    _receiptId = null;
    _order = const Order(id: "0", storeId: "", tableId: "", totalPrice: 0, menus: []);
    notifyListeners();
  }

  /// Order 생성 (기존 Receipt에 새 Order 추가)
  /// 첫 주문이든 추가 주문이든 항상 호출됨
  Future<void> createOrder({
    required String storeId,
    required String tableId,
  }) async {
    if (_receiptId == null) {
      developer.log(
        'createOrder called but receiptId is null',
        name: 'OrderStatusViewModel',
      );
      throw Exception('Receipt ID가 없습니다. 먼저 Receipt을 초기화해주세요.');
    }

    try {
      developer.log(
        'createOrder: receiptId=$_receiptId, storeId=$storeId, tableId=$tableId',
        name: 'OrderStatusViewModel',
      );

      // OrderService를 사용해 새로운 Order 생성
      final newOrder = await _service.createOrder(
        receiptId: _receiptId!,
        storeId: storeId,
        tableId: tableId,
      );

      _order = newOrder;
      developer.log(
        'Order created successfully: ${_order.id}',
        name: 'OrderStatusViewModel',
      );
      notifyListeners();
    } catch (e) {
      developer.log(
        'Error in createOrder: $e',
        name: 'OrderStatusViewModel',
      );
      rethrow;
    }
  }

  /// QR 코드 스캔 시: 기존 미정산 Receipt이 있으면 로드, 없으면 새로 생성
  /// 주의: 이 메서드는 Receipt만 생성/로드하며 Order는 생성하지 않음
  /// Order는 CartScreen에서 실제 주문 시점에 createOrder()로 생성됨
  Future<void> initializeReceipt({
    required String storeId,
    required String tableId,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      developer.log(
        'initializeReceipt: storeId=$storeId, tableId=$tableId',
        name: 'OrderStatusViewModel',
      );

      // 1) 기존 미정산 Receipt 찾기
      final existingReceipt = await _service.findUnpaidOrderByTable(
        storeId: storeId,
        tableId: tableId,
      );

      if (existingReceipt != null) {
        developer.log(
          'Found existing unpaid receipt: ${existingReceipt.id}',
          name: 'OrderStatusViewModel',
        );
        // receiptId만 저장, Order는 생성하지 않음
        _receiptId = existingReceipt.id;
        _order = const Order(id: "0", storeId: "", tableId: "", totalPrice: 0, menus: []);
      } else {
        // 2) 새로운 Receipt 생성 (Order는 아직 생성하지 않음)
        developer.log(
          'Creating new receipt for storeId=$storeId, tableId=$tableId',
          name: 'OrderStatusViewModel',
        );
        final newReceipt = await _service.createReceipt(
          storeId: storeId,
          tableId: tableId,
        );
        developer.log(
          'New receipt created: ${newReceipt.id}',
          name: 'OrderStatusViewModel',
        );
        // receiptId만 저장, Order는 생성하지 않음
        _receiptId = newReceipt.id;
        _order = const Order(id: "0", storeId: "", tableId: "", totalPrice: 0, menus: []);
      }
    } catch (e) {
      developer.log(
        'Error in initializeReceipt: $e',
        name: 'OrderStatusViewModel',
      );
      _receiptId = null;
      _order = const Order(id: "0", storeId: "", tableId: "", totalPrice: 0, menus: []);
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadInitial({required String receiptId}) async {
    _loading = true;
    notifyListeners();

    _receiptId = receiptId;

    try {
      _order = await _service.getOrder(receiptId);
      _handleReceiptStatus(_order);
    } catch (e) {
      _order = const Order(id: "0", storeId: "", tableId: "", totalPrice: 0, menus: []);
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
      _handleReceiptStatus(latest);
      notifyListeners();
    } catch (_) {}
  }

  /// 현재 테이블의 진행 중인 주문을 불러옴 (있을 때만)
  Future<bool> loadExistingOrderForTable({
    required String storeId,
    required String tableId,
  }) async {
    try {
      final existingOrder = await _service.findUnpaidOrderByTable(
        storeId: storeId,
        tableId: tableId,
      );

      if (existingOrder == null) {
        return false;
      }

      _order = existingOrder;
      _receiptId = existingOrder.id;
      _handleReceiptStatus(existingOrder);
      notifyListeners();
      return true;
    } catch (e) {
      developer.log(
        'Error in loadExistingOrderForTable: $e',
        name: 'OrderStatusViewModel',
      );
      return false;
    }
  }

  Future<void> addMenu(OrderMenu menu) async {
    if (_receiptId == null) {
      developer.log('addMenu called but receiptId is null', name: 'OrderStatusViewModel');
      return;
    }

    try {
      // 1) 서버에 메뉴 추가
      await _service.addMenu(orderId: _receiptId!, menu: menu);

      // 2) 로컬 상태 즉시 업데이트 (UI 반응성 향상)
      final updatedMenus = [..._order.menus, menu];
      int newTotalPrice = updatedMenus.fold<int>(
        0,
        (sum, item) => sum + (item.menu.price * item.quantity),
      );
      _order = _order.copyWith(
        menus: updatedMenus,
        totalPrice: newTotalPrice,
      );
      notifyListeners();

      // 3) 백그라운드에서 서버 동기화 (느린 작업)
      unawaited(refresh());
    } catch (e) {
      developer.log('Error adding menu: $e', name: 'OrderStatusViewModel');
    }
  }

  Future<void> cancelMenu(String menuId) async {
    if (_receiptId == null) return;

    try {
      // 1) 서버에서 메뉴 취소
      await _service.cancelMenu(orderId: _receiptId!, menuId: menuId);

      // 2) 로컬 상태 즉시 업데이트 (UI 반응성 향상)
      final updatedMenus = _order.menus
          .map((menu) =>
              menu.id == menuId ? menu.copyWith(status: OrderMenuStatus.canceled) : menu)
          .toList();

      int newTotalPrice = updatedMenus.fold<int>(
        0,
        (sum, item) =>
            item.status == OrderMenuStatus.canceled ? sum : sum + (item.menu.price * item.quantity),
      );

      _order = _order.copyWith(
        menus: updatedMenus,
        totalPrice: newTotalPrice,
      );
      notifyListeners();

      // 3) 백그라운드에서 서버 동기화 (느린 작업)
      unawaited(refresh());
    } catch (_) {}
  }

  void _handleReceiptStatus(Order latest) {
    if (latest.status.isPaid) {
      _receiptId = null;
    } else {
      _receiptId ??= latest.id;
    }
  }
}
