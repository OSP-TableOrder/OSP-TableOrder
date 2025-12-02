import 'package:table_order/models/admin/order_log.dart';
import 'package:table_order/models/admin/table_order_info.dart';

/// 주문 로그 분석 Service
/// 테이블 주문 상태에서 신규 주문 항목들을 추출하여 알림 로그 생성
class OrderLogService {
  /// 현재 테이블 상태에서 신규 주문(ORDERED 상태)을 추려서 알림 로그로 변환
  List<OrderLog> buildOrderLogs(List<TableOrderInfo> tables) {
    final logs = <OrderLog>[];

    for (final table in tables) {
      for (final order in table.orders) {
        final newItems = order.items.where(_isNewlyOrderedItem).toList();
        if (newItems.isEmpty) continue;

        final summary = newItems.map(_formatMenuSummary).join(', ');
        logs.add(
          OrderLog(
            tableName: table.tableName,
            orderSummary: summary,
            time: order.orderTime ?? '-',
          ),
        );
      }
    }

    return logs;
  }

  bool _isNewlyOrderedItem(dynamic item) {
    if (item is! Map) return false;
    final rawStatus = (item['status'] as String?) ?? 'ORDERED';
    final normalized = rawStatus.toUpperCase();
    return normalized.contains('ORDERED');
  }

  String _formatMenuSummary(dynamic item) {
    if (item is! Map) return item.toString();
    final name = item['name'] ?? '메뉴';
    final quantity = item['quantity'] ?? 1;
    return '$name x$quantity';
  }
}
