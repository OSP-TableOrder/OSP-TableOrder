import 'package:flutter/material.dart';
import 'package:table_order/models/admin/table_order_info.dart';
import 'package:table_order/service/admin/table_connect_service.dart';
import 'package:table_order/service/admin/table_order_service.dart';

class TableOrderProvider extends ChangeNotifier {
  // 테이블 목록(이름/ID)을 관리하는 서비스
  final TableConnectService _connectService = TableConnectService();

  // 주문 내역을 가져오는 서비스
  final TableOrderService _orderService = TableOrderService();

  List<TableOrderInfo> _tables = [];
  List<TableOrderInfo> get tables => _tables;

  Future<void> loadTables() async {
    try {
      final tableModels = await _connectService.getTables();

      final dummyOrders = await _orderService.getTableOrders();

      _tables = tableModels.map((model) {
        final matchingOrder = dummyOrders.firstWhere(
          (dummy) => model.name.contains(dummy.tableName),
          orElse: () => TableOrderInfo(tableName: model.name),
        );

        if (matchingOrder.items.isNotEmpty ||
            matchingOrder.hasNewOrder ||
            matchingOrder.hasCallRequest) {
          return TableOrderInfo(
            tableName: model.name,
            items: List.from(matchingOrder.items),
            totalPrice: matchingOrder.totalPrice,
            orderTime: matchingOrder.orderTime,
            hasNewOrder: matchingOrder.hasNewOrder,
            hasCallRequest: matchingOrder.hasCallRequest,
            orderStatus: matchingOrder.orderStatus,
          );
        }

        // 매칭되는 주문이 없으면 빈 테이블로 생성
        return TableOrderInfo(
          tableName: model.name,
          items: [],
          totalPrice: 0,
          hasNewOrder: false,
          hasCallRequest: false,
          orderStatus: OrderStatus.empty,
        );
      }).toList();

      notifyListeners(); // 화면 갱신 요청
    } catch (e) {
      // print("테이블 목록 로드 실패: $e");
    }
  }

  // 메뉴 추가
  void addMenuItem(int tableIndex, String name, int price, int quantity) {
    if (tableIndex < 0 || tableIndex >= _tables.length) return;

    final table = _tables[tableIndex];

    // 이미 있는 메뉴인지 확인 (이름으로 구분)
    final existingIndex = table.items.indexWhere((item) {
      if (item is Map) return item['name'] == name;
      return false;
    });

    if (existingIndex != -1) {
      // 이미 있으면 수량 증가
      final existingItem = table.items[existingIndex];
      if (existingItem is Map) {
        int currentQty = existingItem['quantity'] ?? 1;
        existingItem['quantity'] = currentQty + quantity;
      }
    } else {
      // 없으면 새로 추가
      table.items.add({"name": name, "price": price, "quantity": quantity});
    }

    _updateTableStatus(table);
    notifyListeners();
  }

  // 메뉴 부분 취소 (수량 지정 삭제)
  void cancelOrderItem(int tableIndex, int itemIndex, int cancelQuantity) {
    if (tableIndex < 0 || tableIndex >= _tables.length) return;

    final table = _tables[tableIndex];
    if (itemIndex < 0 || itemIndex >= table.items.length) return;

    final dynamic item = table.items[itemIndex];

    if (item is Map) {
      int currentQty = item['quantity'] ?? 1;

      if (cancelQuantity >= currentQty) {
        // 전체 삭제
        table.items.removeAt(itemIndex);
      } else {
        // 부분 감소
        item['quantity'] = currentQty - cancelQuantity;
      }
    } else {
      // Map이 아닌 경우 강제 삭제
      table.items.removeAt(itemIndex);
    }

    _updateTableStatus(table);
    notifyListeners();
  }

  // 총 가격 계산 및 상태 업데이트
  void _updateTableStatus(TableOrderInfo table) {
    int total = 0;
    for (var item in table.items) {
      if (item is Map) {
        int p = item['price'] ?? 0;
        int q = item['quantity'] ?? 0;
        total += (p * q);
      }
    }
    table.totalPrice = total;

    // 주문이 있으면 상태 변경
    if (table.items.isNotEmpty) {
      table.orderStatus = OrderStatus.ordered;
    } else {
      table.orderStatus = OrderStatus.empty;
    }
  }

  // 신규 주문 확인 처리
  void checkNewOrder(int index) {
    if (index >= 0 && index < _tables.length) {
      _tables[index].hasNewOrder = false;
      notifyListeners();
    }
  }

  // 호출 요청 확인 처리
  void checkCallRequest(int index) {
    if (index >= 0 && index < _tables.length) {
      _tables[index].hasCallRequest = false;
      notifyListeners();
    }
  }
}
