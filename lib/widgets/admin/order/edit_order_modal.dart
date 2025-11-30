import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/models/admin/table_order_info.dart';
import 'package:table_order/provider/admin/table_order_provider.dart';
import 'package:table_order/widgets/admin/order/add_order_modal.dart';
import 'package:table_order/widgets/admin/order/cancel_order_modal.dart';

class EditOrderModal extends StatefulWidget {
  final int tableIndex;
  final TableOrderInfo table;

  const EditOrderModal({
    super.key,
    required this.tableIndex,
    required this.table,
  });

  @override
  State<EditOrderModal> createState() => _EditOrderModalState();
}

class _EditOrderModalState extends State<EditOrderModal> {
  // 메뉴 추가하기 버튼 로직
  void _openMenuSelectionModal() async {
    final List<Map<String, dynamic>>? result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddOrderModal(),
    );

    if (result != null && result.isNotEmpty) {
      if (!mounted) return;
      final provider = context.read<TableOrderProvider>();

      // 선택된 메뉴들을 Provider에 추가 (이것이 카드뷰 등 모든 곳에 반영됨)
      for (var item in result) {
        provider.addMenuItem(
          widget.tableIndex,
          item['name'],
          item['price'],
          item['quantity'],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provider.watch를 통해 데이터 변경 시 UI 자동 갱신
    final table = context.watch<TableOrderProvider>().tables[widget.tableIndex];

    return Column(
      children: [
        // 현재 주문 목록 리스트
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: table.items.isEmpty
                ? const Center(child: Text("현재 주문 내역이 없습니다."))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: table.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dynamic item = table.items[index];
                      final String name = item is Map
                          ? item['name']
                          : item.toString();
                      final int quantity = item is Map
                          ? (item['quantity'] ?? 1)
                          : 1;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // 메뉴명
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            // 수량 표시 및 삭제(-) 버튼
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    "x $quantity",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 취소 버튼
                                  InkWell(
                                    onTap: () {
                                      // 취소 모달 띄우기
                                      showDialog(
                                        context: context,
                                        builder: (context) => CancelOrderModal(
                                          itemName: name,
                                          currentQty: quantity,
                                          onConfirm: (cancelQty) {
                                            // 취소 확정 시 Provider 호출 -> 모든 화면 반영
                                            context
                                                .read<TableOrderProvider>()
                                                .cancelOrderItem(
                                                  widget.tableIndex,
                                                  index,
                                                  cancelQty,
                                                );
                                          },
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.redAccent,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),

        // 하단 버튼 영역
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _openMenuSelectionModal,
              icon: const Icon(Icons.add),
              label: const Text(
                "메뉴 추가하기",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2d7ff9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
