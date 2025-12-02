import 'dart:developer' as developer;
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
    _order = const Order(
      id: "0",
      storeId: "",
      tableId: "",
      totalPrice: 0,
      menus: [],
    );
    notifyListeners();
  }

  /// 새로운 주문 생성
  Future<void> createOrder({
    required String storeId,
    required String tableId,
  }) async {
    try {
      developer.log(
        'createOrder: storeId=$storeId, tableId=$tableId',
        name: 'OrderStatusViewModel',
      );
      _order = await _service.createOrder(
        storeId: storeId,
        tableId: tableId,
      );
      developer.log(
        'Order created successfully: ${_order.id}',
        name: 'OrderStatusViewModel',
      );
      _receiptId = _order.id;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Error in createOrder: $e',
        name: 'OrderStatusViewModel',
      );
      _order = const Order(
        id: "0",
        storeId: "",
        tableId: "",
        totalPrice: 0,
        menus: [],
      );
      rethrow;
    }
  }

  /// QR 코드 스캔 시: 기존 미정산 주문이 있으면 로드, 없으면 새로 생성
  Future<void> initializeOrderForTable({
    required String storeId,
    required String tableId,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      developer.log(
        'initializeOrderForTable: storeId=$storeId, tableId=$tableId',
        name: 'OrderStatusViewModel',
      );

      // 1) 기존 미정산 주문 찾기
      final existingOrder = await _service.findUnpaidOrderByTable(
        storeId: storeId,
        tableId: tableId,
      );

      if (existingOrder != null) {
        developer.log(
          'Found existing unpaid order: ${existingOrder.id}',
          name: 'OrderStatusViewModel',
        );
        _order = existingOrder;
        _receiptId = existingOrder.id;
      } else {
        // 2) 새로운 주문 생성
        developer.log(
          'Creating new order for storeId=$storeId, tableId=$tableId',
          name: 'OrderStatusViewModel',
        );
        _order = await _service.createOrder(
          storeId: storeId,
          tableId: tableId,
        );
        developer.log(
          'New order created: ${_order.id}',
          name: 'OrderStatusViewModel',
        );
        _receiptId = _order.id;
      }
    } catch (e) {
      developer.log(
        'Error in initializeOrderForTable: $e',
        name: 'OrderStatusViewModel',
      );
      _order = const Order(
        id: "0",
        storeId: "",
        tableId: "",
        totalPrice: 0,
        menus: [],
      );
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
    } catch (e) {
      _order = const Order(
        id: "0",
        storeId: "",
        tableId: "",
        totalPrice: 0,
        menus: [],
      );
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
      await _service.addMenu(orderId: _receiptId!, menu: menu);

      // 서버 변경사항 반영
      await refresh();
    } catch (e) {
      developer.log('Error adding menu: $e', name: 'OrderStatusViewModel');
    }
  }

  Future<void> cancelMenu(String menuId) async {
    if (_receiptId == null) return;

    try {
      await _service.cancelMenu(orderId: _receiptId!, menuId: menuId);

      // 최신 상태 갱신
      await refresh();
    } catch (_) {}
  }
}
