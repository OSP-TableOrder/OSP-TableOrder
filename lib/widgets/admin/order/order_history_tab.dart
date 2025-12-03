import 'package:flutter/material.dart';
import 'package:table_order/models/admin/table_order_info.dart';
import 'package:table_order/utils/won_formatter.dart';
import 'package:table_order/models/common/order_menu_status.dart';

class OrderHistoryTab extends StatelessWidget {
  final TableOrderInfo table;

  const OrderHistoryTab({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    // 모든 주문의 메뉴 항목들 수집
    final allItems = <dynamic>[];
    final orderTimes = <String>[];
    for (final order in table.orders) {
      allItems.addAll(order.items);
      if (order.orderTime != null) {
        orderTimes.add(order.orderTime!);
      }
    }

    final hasOrders = allItems.isNotEmpty;
    final orderTimeDisplay = orderTimes.isNotEmpty ? orderTimes.join(", ") : "-";

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("테이블명", table.tableName),
          _buildInfoRow("주문 상태", hasOrders ? "주문중" : "비어있음"),
          _buildInfoRow("주문 시각", orderTimeDisplay),

          const SizedBox(height: 20),
          const Divider(thickness: 1),

          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text("메뉴명", style: TextStyle(color: Colors.grey)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "수량",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "금액",
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "시간",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "상태",
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1),

          // 리스트
          Expanded(
            child: allItems.isEmpty
                ? const Center(
                    child: Text(
                      "주문 내역이 없습니다.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: allItems.length,
                    itemBuilder: (_, i) {
                      final item = allItems[i];
                      final name = item is Map ? item['name'] : item.toString();
                      final qty = item is Map ? item['quantity'] : 1;
                      final price = item is Map ? item['price'] : 0;
                      final status = item is Map ? item['status'] ?? 'ORDERED' : 'ORDERED';

                      // orderedAt을 안전하게 처리 (DateTime 또는 String 가능) - HH:mm 형식
                      String? orderedAtStr;
                      if (item is Map && item['orderedAt'] != null) {
                        final orderedAtValue = item['orderedAt'];
                        DateTime? dateTime;

                        if (orderedAtValue is String) {
                          try {
                            dateTime = DateTime.parse(orderedAtValue);
                          } catch (_) {
                            orderedAtStr = orderedAtValue;
                          }
                        } else if (orderedAtValue is DateTime) {
                          dateTime = orderedAtValue;
                        }

                        if (dateTime != null) {
                          final hour = dateTime.hour.toString().padLeft(2, '0');
                          final minute = dateTime.minute.toString().padLeft(2, '0');
                          orderedAtStr = '$hour:$minute';
                        }
                      }

                      final total = price * qty;

                      final statusLabel = _getStatusLabel(status);
                      final statusColor = _getStatusColor(status);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "$qty",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                formatWon(total),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                orderedAtStr ?? "-",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const Divider(thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "총 결제 금액",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  formatWon(table.totalPrice),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2d7ff9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    final menuStatus = orderMenuStatusFromCode(status);
    return menuStatus.label;
  }

  Color _getStatusColor(String status) {
    final menuStatus = orderMenuStatusFromCode(status);
    return menuStatus.fg;
  }
}
