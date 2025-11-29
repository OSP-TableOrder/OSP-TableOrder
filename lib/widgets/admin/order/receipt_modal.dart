import 'package:flutter/material.dart';
import 'package:table_order/models/admin/table_order_info.dart';
import 'package:table_order/widgets/admin/order/edit_order_modal.dart';
import 'package:table_order/widgets/admin/order/order_history_tab.dart';

class ReceiptModal extends StatelessWidget {
  final TableOrderInfo table;
  final int tableIndex;

  const ReceiptModal({
    super.key,
    required this.table,
    required this.tableIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // 탭 바
            const TabBar(
              labelColor: Color(0xff2d7ff9),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xff2d7ff9),
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: [
                Tab(text: "주문 내역"),
                Tab(text: "주문 수정"),
              ],
            ),

            // 탭 뷰
            Expanded(
              child: TabBarView(
                children: [
                  // 주문 내역
                  OrderHistoryTab(table: table),

                  // 주문 수정
                  EditOrderModal(tableIndex: tableIndex, table: table),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
