import 'package:flutter/material.dart';
import 'package:table_order/models/admin/order_log.dart';

class OrderNotificationPanel extends StatelessWidget {
  final List<OrderLog> orderLogs;
  final VoidCallback onClose;

  const OrderNotificationPanel({
    super.key,
    required this.orderLogs,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  "주문 알림",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),

            const SizedBox(height: 8),

            if (orderLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  "새로운 주문이 없습니다.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              for (final log in orderLogs)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          log.tableName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          log.time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        log.orderSummary,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 8),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
