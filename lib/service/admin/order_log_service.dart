import 'package:table_order/models/admin/order_log.dart';
import 'package:table_order/models/admin/table_order_info.dart';

/// 주문 로그 분석 Service
/// 테이블 주문 상태에서 신규 주문 항목들을 추출하여 알림 로그 생성
class OrderLogService {
  /// 현재 테이블 상태에서 신규 주문(ORDERED 상태)을 추려서 알림 로그로 변환
  /// 모든 테이블의 주문을 시간순으로 정렬하여 반환
  List<OrderLog> buildOrderLogs(List<TableOrderInfo> tables) {
    // 1. 모든 테이블의 주문을 시간 정보와 함께 수집
    final logWithTime = <({OrderLog log, DateTime? orderDateTime})>[];

    for (final table in tables) {
      for (final order in table.orders) {
        final newItems = order.items.where(_isNewlyOrderedItem).toList();
        if (newItems.isEmpty) continue;

        // 주문 시간을 파싱 (HH:mm 형식)
        DateTime? orderDateTime;
        if (order.orderTime != null && order.orderTime!.contains(':')) {
          try {
            final parts = order.orderTime!.split(':');
            if (parts.length == 2) {
              final hour = int.parse(parts[0]);
              final minute = int.parse(parts[1]);
              final now = DateTime.now();
              orderDateTime = DateTime(now.year, now.month, now.day, hour, minute);
            }
          } catch (_) {
            // 파싱 실패 시 null 유지
          }
        }

        final summary = newItems.map(_formatMenuSummary).join(', ');
        logWithTime.add(
          (
            log: OrderLog(
              tableName: table.tableName,
              orderSummary: summary,
              time: order.orderTime ?? '-',
            ),
            orderDateTime: orderDateTime,
          ),
        );
      }
    }

    // 2. 시간순으로 정렬 (오래된 주문이 먼저)
    logWithTime.sort((a, b) {
      // 시간 정보가 없는 경우 뒤로 보냄
      if (a.orderDateTime == null && b.orderDateTime == null) return 0;
      if (a.orderDateTime == null) return 1;
      if (b.orderDateTime == null) return -1;

      return a.orderDateTime!.compareTo(b.orderDateTime!);
    });

    // 3. OrderLog만 추출
    return logWithTime.map((item) => item.log).toList();
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
