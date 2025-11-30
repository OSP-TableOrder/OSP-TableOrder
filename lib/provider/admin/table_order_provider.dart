import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:table_order/models/admin/table_order_info.dart';
import 'package:table_order/service/admin/call_staff_service.dart';
import 'package:table_order/service/admin/table_connect_service.dart';
import 'package:table_order/service/admin/table_order_service.dart';

class TableOrderProvider extends ChangeNotifier {
  // 테이블 목록(이름/ID)을 관리하는 서비스
  final TableConnectService _connectService = TableConnectService();

  // 주문 내역을 가져오는 서비스
  final TableOrderService _orderService = TableOrderService();
  final CallStaffService _callStaffService = CallStaffService();

  List<TableOrderInfo> _tables = [];
  List<TableOrderInfo> get tables => _tables;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> loadTables(String storeId) async {
    _loading = true;
    notifyListeners();

    try {
      developer.log(
        'Loading tables for storeId=$storeId',
        name: 'TableOrderProvider',
      );

      // 1) 테이블 목록 조회
      final tableModels = await _connectService.getTables(storeId);
      developer.log(
        'Found ${tableModels.length} tables',
        name: 'TableOrderProvider',
      );

      // 2) 미정산 주문 조회
      final ordersFromFirestore =
          await _orderService.getUnpaidOrdersByStore(storeId);
      developer.log(
        'Found ${ordersFromFirestore.length} tables with unpaid orders',
        name: 'TableOrderProvider',
      );

      // 2-1) 직원 호출 목록 조회
      final callRequests = await _callStaffService.getLogs(storeId);
      final tablesWithCallRequest = callRequests
          .where((log) => !log.resolved)
          .map((log) => log.tableId)
          .toSet();

      // 3) 테이블별로 주문 정보 병합
      final tableOrderMap = <String, TableOrderInfo>{};
      for (final order in ordersFromFirestore) {
        final totalItemCount =
            order.orders.fold<int>(0, (sum, o) => sum + o.items.length);
        developer.log(
          'Adding order to map: tableId=${order.tableId}, tableName=${order.tableName}, items=$totalItemCount',
          name: 'TableOrderProvider',
        );
        tableOrderMap[order.tableId] = order;
      }

      developer.log(
        'TableOrderMap size: ${tableOrderMap.length}, keys: ${tableOrderMap.keys}',
        name: 'TableOrderProvider',
      );

      _tables = tableModels.map((tableModel) {
        developer.log(
          'Mapping tableModel: id=${tableModel.id}, name=${tableModel.name}',
          name: 'TableOrderProvider',
        );

        // Firestore의 주문 데이터가 있으면 사용, 없으면 빈 테이블
        final found = tableOrderMap[tableModel.id];
        if (found != null) {
          developer.log(
            'Found ${found.orders.length} order(s) for table ${tableModel.name}',
            name: 'TableOrderProvider',
          );
          found.hasCallRequest = tablesWithCallRequest.contains(found.tableId);
          return found;
        } else {
          developer.log(
            'No order found for table ${tableModel.name}',
            name: 'TableOrderProvider',
          );
          return TableOrderInfo(
            tableId: tableModel.id,
            tableName: tableModel.name,
            hasCallRequest: tablesWithCallRequest.contains(tableModel.id),
          );
        }
      }).toList();

      developer.log(
        'Tables loaded: ${_tables.length}. Details: ${_tables.map((t) => "${t.tableName}(${t.orders.length} orders)").toList()}',
        name: 'TableOrderProvider',
      );

      notifyListeners();
    } catch (e) {
      developer.log(
        'Error loading tables: $e',
        name: 'TableOrderProvider',
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // 메뉴 추가 (전체 메뉴 객체 포함)
  Future<void> addMenuItemWithMenu(
    int tableIndex,
    int orderIndex,
    Map<String, dynamic> menu,
    int quantity,
  ) async {
    if (tableIndex < 0 || tableIndex >= _tables.length) return;

    final table = _tables[tableIndex];
    if (orderIndex < 0 || orderIndex >= table.orders.length) return;

    final order = table.orders[orderIndex];
    final menuId = menu['id'] as String? ?? '';

    // 이미 있는 메뉴인지 확인 (ID로 구분)
    final existingIndex = order.items.indexWhere((item) {
      if (item is Map) {
        final itemMenu = item['menu'];
        if (itemMenu is Map) {
          return itemMenu['id'] == menuId;
        }
        return item['id'] == menuId;
      }
      return false;
    });

    if (existingIndex != -1) {
      // 이미 있으면 수량 증가
      final existingItem = order.items[existingIndex];
      if (existingItem is Map) {
        int currentQty = existingItem['quantity'] ?? 1;
        existingItem['quantity'] = currentQty + quantity;
      }
    } else {
      // 없으면 새로 추가 (유저 메뉴와 동일한 구조)
      order.items.add({
        "menu": menu,
        "quantity": quantity,
        "status": "OrderMenuStatus.ordered",
      });
    }

    _updateOrderStatus(order);
    notifyListeners();

    // Firestore에 저장
    final success = await _orderService.addMenuToOrder(
      orderId: order.orderId,
      menu: menu,
      quantity: quantity,
    );
    if (!success) {
      developer.log(
        'Failed to add menu to order in Firestore',
        name: 'TableOrderProvider',
      );
    }
  }

  // 메뉴 추가
  Future<void> addMenuItem(int tableIndex, int orderIndex, String name, int price, int quantity) async {
    if (tableIndex < 0 || tableIndex >= _tables.length) return;

    final table = _tables[tableIndex];
    if (orderIndex < 0 || orderIndex >= table.orders.length) return;

    final order = table.orders[orderIndex];

    // 이미 있는 메뉴인지 확인 (이름으로 구분)
    // 참고: addMenuItem은 menuId가 없으므로 여전히 이름으로 비교
    final existingIndex = order.items.indexWhere((item) {
      if (item is Map) return item['name'] == name;
      return false;
    });

    if (existingIndex != -1) {
      // 이미 있으면 수량 증가
      final existingItem = order.items[existingIndex];
      if (existingItem is Map) {
        int currentQty = existingItem['quantity'] ?? 1;
        existingItem['quantity'] = currentQty + quantity;
      }
    } else {
      // 없으면 새로 추가 (상태는 '접수 대기'로 설정)
      order.items.add({
        "name": name,
        "price": price,
        "quantity": quantity,
        "status": "ORDERED",
      });
    }

    _updateOrderStatus(order);
    notifyListeners();

    // Firestore에 저장
    final success = await _orderService.addMenuToOrder(
      orderId: order.orderId,
      menuName: name,
      price: price,
      quantity: quantity,
    );
    if (!success) {
      developer.log(
        'Failed to add menu to order in Firestore',
        name: 'TableOrderProvider',
      );
    }
  }

  // 메뉴 부분 취소 (수량 지정 삭제)
  void cancelOrderItem(int tableIndex, int orderIndex, int itemIndex, int cancelQuantity) {
    if (tableIndex < 0 || tableIndex >= _tables.length) return;

    final table = _tables[tableIndex];
    if (orderIndex < 0 || orderIndex >= table.orders.length) return;

    final order = table.orders[orderIndex];
    if (itemIndex < 0 || itemIndex >= order.items.length) return;

    final dynamic item = order.items[itemIndex];

    if (item is Map) {
      int currentQty = item['quantity'] ?? 1;

      if (cancelQuantity >= currentQty) {
        // 전체 삭제
        order.items.removeAt(itemIndex);
      } else {
        // 부분 감소
        item['quantity'] = currentQty - cancelQuantity;
      }
    } else {
      // Map이 아닌 경우 강제 삭제
      order.items.removeAt(itemIndex);
    }

    _updateOrderStatus(order);
    notifyListeners();
  }

  // 총 가격 계산 및 상태 업데이트
  void _updateOrderStatus(TableOrder order) {
    int total = 0;
    for (var item in order.items) {
      if (item is Map) {
        int p = item['price'] ?? 0;
        int q = item['quantity'] ?? 0;
        total += (p * q);
      }
    }
    order.totalPrice = total;

    // 주문이 있으면 상태 변경
    if (order.items.isNotEmpty) {
      order.orderStatus = OrderStatus.ordered;
    } else {
      order.orderStatus = OrderStatus.empty;
    }
  }

  // 신규 주문 확인 처리 - 모든 주문의 hasNewOrder 플래그 초기화
  void checkNewOrder(int index) {
    if (index >= 0 && index < _tables.length) {
      final table = _tables[index];
      for (final order in table.orders) {
        order.hasNewOrder = false;
      }
      notifyListeners();
    }
  }

  // 호출 요청 확인 처리
  Future<void> checkCallRequest(int index, String storeId) async {
    if (index >= 0 && index < _tables.length) {
      final table = _tables[index];
      try {
        await _callStaffService.resolveCallRequests(
          storeId: storeId,
          tableId: table.tableId,
        );
      } catch (e) {
        developer.log(
          'Failed to resolve call request: $e',
          name: 'TableOrderProvider',
        );
      }
      table.hasCallRequest = false;
      notifyListeners();
    }
  }

  // 메뉴 수량 변경
  Future<void> updateMenuQuantity(int tableIndex, int orderIndex, int itemIndex, int newQuantity) async {
    if (tableIndex < 0 || tableIndex >= _tables.length) return;

    final table = _tables[tableIndex];
    if (orderIndex < 0 || orderIndex >= table.orders.length) return;

    final order = table.orders[orderIndex];
    if (itemIndex < 0 || itemIndex >= order.items.length) return;
    if (newQuantity < 1) return;

    final dynamic item = order.items[itemIndex];

    if (item is Map) {
      item['quantity'] = newQuantity;
      _updateOrderStatus(order);
      notifyListeners();

      // Firestore에 저장
      final success = await _orderService.updateMenuQuantity(
        orderId: order.orderId,
        menuIndex: itemIndex,
        newQuantity: newQuantity,
      );
      if (!success) {
        developer.log(
          'Failed to update menu quantity in Firestore',
          name: 'TableOrderProvider',
        );
      }
    }
  }

  // 메뉴 상태 변경 (상태 전환 규칙 적용)
  // ORDERED(접수 대기) -> COOKING(조리 중), CANCELED(취소됨)
  // COOKING(조리 중) -> COMPLETED(완료), CANCELED(취소됨)
  // COMPLETED, CANCELED -> 변경 불가
  Future<bool> updateMenuStatus(int tableIndex, int orderIndex, int itemIndex, String newStatus) async {
    if (tableIndex < 0 || tableIndex >= _tables.length) return false;

    final table = _tables[tableIndex];
    if (orderIndex < 0 || orderIndex >= table.orders.length) return false;

    final order = table.orders[orderIndex];
    if (itemIndex < 0 || itemIndex >= order.items.length) return false;

    final dynamic item = order.items[itemIndex];

    if (item is Map) {
      final currentStatus = item['status'] ?? 'ORDERED';

      // 상태 전환 규칙 검증
      final canTransition = _canTransitionStatus(currentStatus, newStatus);
      if (!canTransition) {
        developer.log(
          'Cannot transition from $currentStatus to $newStatus',
          name: 'TableOrderProvider',
        );
        return false;
      }

      item['status'] = newStatus;
      notifyListeners();

      // Firestore에 저장
      final success = await _orderService.updateMenuStatus(
        orderId: order.orderId,
        menuIndex: itemIndex,
        newStatus: newStatus,
      );
      if (!success) {
        developer.log(
          'Failed to update menu status in Firestore',
          name: 'TableOrderProvider',
        );
        return false;
      }

      return true;
    }

    return false;
  }

  // 상태 전환 가능 여부 확인
  bool _canTransitionStatus(String currentStatus, String newStatus) {
    switch (currentStatus) {
      case 'ORDERED':
        // 접수 대기 -> 조리 중, 취소됨만 가능
        return newStatus == 'COOKING' || newStatus == 'CANCELED';
      case 'COOKING':
        // 조리 중 -> 완료, 취소됨만 가능
        return newStatus == 'COMPLETED' || newStatus == 'CANCELED';
      case 'COMPLETED':
      case 'CANCELED':
        // 완료, 취소됨 -> 변경 불가
        return false;
      default:
        return false;
    }
  }

  // 주문 정산 (주문 상태를 unpaid에서 paid로 변경)
  Future<bool> settleOrder(int tableIndex, int orderIndex) async {
    try {
      if (tableIndex < 0 || tableIndex >= _tables.length) return false;

      final table = _tables[tableIndex];
      if (orderIndex < 0 || orderIndex >= table.orders.length) return false;

      final order = table.orders[orderIndex];

      developer.log(
        'Settling order: ${order.orderId}',
        name: 'TableOrderProvider',
      );

      final success = await _orderService.updateOrderStatus(
        orderId: order.orderId,
        newStatus: 'paid',
      );

      if (success) {
        developer.log(
          'Order ${order.orderId} settled successfully',
          name: 'TableOrderProvider',
        );
        // 주문이 정산되었으므로 주문을 목록에서 제거
        table.orders.removeAt(orderIndex);
        notifyListeners();
      }

      return success;
    } catch (e) {
      developer.log(
        'Error settling order: $e',
        name: 'TableOrderProvider',
      );
      return false;
    }
  }
}
