import 'package:flutter/material.dart';
import 'package:table_order/models/admin/table_order_info.dart';

class OrderHistoryTab extends StatelessWidget {
  final TableOrderInfo table;

  const OrderHistoryTab({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("테이블명", table.tableName),
          _buildInfoRow("주문 상태", table.items.isEmpty ? "비어있음" : "주문중"),
          _buildInfoRow("주문 시각", table.orderTime ?? "-"),

          const SizedBox(height: 20),
          const Divider(thickness: 1),

          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: const [
                Expanded(
                  flex: 5,
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
                  flex: 3,
                  child: Text(
                    "금액",
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
            child: table.items.isEmpty
                ? const Center(
                    child: Text(
                      "주문 내역이 없습니다.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: table.items.length,
                    itemBuilder: (_, i) {
                      final item = table.items[i];
                      final name = item is Map ? item['name'] : item.toString();
                      final qty = item is Map ? item['quantity'] : 1;
                      final price = item is Map ? item['price'] : 0;
                      final total = price * qty;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
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
                              flex: 3,
                              child: Text(
                                "$total원",
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 16),
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
                  "${table.totalPrice}원",
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
}
