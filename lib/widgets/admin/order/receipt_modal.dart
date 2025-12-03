import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/models/admin/table_order_info.dart';
import 'package:table_order/provider/admin/order_provider.dart';
import 'package:table_order/widgets/admin/order/add_order_modal.dart';
import 'package:table_order/widgets/admin/order/edit_order_modal.dart';
import 'package:table_order/widgets/admin/order/order_history_tab.dart';

class ReceiptModal extends StatelessWidget {
  final TableOrderInfo table;
  final int tableIndex;
  final String? storeId;

  const ReceiptModal({
    super.key,
    required this.table,
    required this.tableIndex,
    this.storeId,
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

                  // 주문 수정 - 다중 주문 지원
                  _buildOrderEditView(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 주문 수정 뷰 - 다중 주문을 선택할 수 있도록 구성
  Widget _buildOrderEditView(BuildContext context) {
    if (table.orders.isEmpty) {
      return const Center(child: Text("수정할 주문이 없습니다."));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: table.orders.length,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
              child: EditOrderModal(
                tableIndex: tableIndex,
                orderIndex: i,
                table: table,
                storeId: storeId,
                showOrderHeader: table.orders.length > 1,
                orderLabel: table.orders[i].orderTime != null
                    ? "${table.orders[i].orderTime} 주문"
                    : "주문 ${i + 1}",
                showActionButtons: false,
              ),
            ),
          ),
        ),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (table.orders.isEmpty) {
      return const SizedBox.shrink();
    }

    const int targetOrderIndex = 0; // 항상 가장 최근 주문에 메뉴 추가/정산

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final provider = context.read<OrderProvider>();
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                final success = await provider.settleReceipt(
                  tableIndex,
                  targetOrderIndex,
                );

                if (!navigator.mounted) return;

                if (success) {
                  if (storeId != null && storeId!.isNotEmpty) {
                    await provider.loadTables(storeId!);
                  }
                  navigator.pop();
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('정산 처리에 실패했습니다.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "정산",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleAddMenu(context, targetOrderIndex),
              icon: const Icon(Icons.add),
              label: const Text(
                "메뉴 추가",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2d7ff9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddMenu(BuildContext context, int orderIndex) async {
    if (storeId == null || storeId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가게 정보가 없습니다.')),
      );
      return;
    }

    final List<Map<String, dynamic>>? result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddOrderModal(
        storeId: storeId,
      ),
    );

    if (result == null || result.isEmpty) return;

    final provider = context.read<OrderProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    for (final menuData in result) {
      try {
        final menu = menuData['menu'] as Map<String, dynamic>;
        final quantity = menuData['quantity'] as int? ?? 1;

        await provider.addMenuToReceipt(
          tableIndex: tableIndex,
          orderIndex: orderIndex,
          menuData: {
            ...menu,
            'quantity': quantity,
          },
        );
      } catch (e) {
        final menuName = (menuData['menu'] as Map<String, dynamic>?)?['name'] ?? '메뉴';
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('메뉴 추가 실패: $menuName')),
        );
      }
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('${result.length}개 메뉴가 추가되었습니다.')),
    );
  }
}
