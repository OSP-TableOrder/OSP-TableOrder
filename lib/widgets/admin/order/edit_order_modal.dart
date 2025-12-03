import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/models/admin/table_order_info.dart';
import 'package:table_order/models/common/order_menu_status.dart';
import 'package:table_order/provider/admin/order_provider.dart';
import 'package:table_order/widgets/admin/order/add_order_modal.dart';
import 'package:table_order/widgets/admin/order/edit_quantity_modal.dart';

class EditOrderModal extends StatefulWidget {
  final int tableIndex;
  final int orderIndex;
  final TableOrderInfo table;
  final String? storeId;
  final bool showOrderHeader;
  final String? orderLabel;
  final bool showActionButtons;

  const EditOrderModal({
    super.key,
    required this.tableIndex,
    required this.orderIndex,
    required this.table,
    this.storeId,
    this.showOrderHeader = false,
    this.orderLabel,
    this.showActionButtons = true,
  });

  @override
  State<EditOrderModal> createState() => _EditOrderModalState();
}

class _EditOrderModalState extends State<EditOrderModal> {
  // 메뉴 추가하기 버튼 로직
  void _openMenuSelectionModal() async {
    developer.log('_openMenuSelectionModal - widget.storeId: ${widget.storeId}',
      name: 'EditOrderModal');

    final List<Map<String, dynamic>>? result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddOrderModal(
        storeId: widget.storeId,
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (!mounted) return;

      developer.log(
        'Adding ${result.length} menu item(s) to receipt ${widget.table.orders[widget.orderIndex].orderId}',
        name: 'EditOrderModal',
      );

      final provider = context.read<OrderProvider>();
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // 선택된 메뉴들을 주문에 추가
      for (final menuData in result) {
        try {
          // AddOrderModal에서 반환하는 형식: { menu: {...}, quantity: n }
          final menu = menuData['menu'] as Map<String, dynamic>;
          final quantity = menuData['quantity'] as int? ?? 1;

          developer.log(
            'Menu to add: ${menu['name']}, quantity: $quantity',
            name: 'EditOrderModal',
          );

          // 메뉴 추가 API 호출 (OrderService를 통해 Receipts 컬렉션 업데이트)
          await provider.addMenuToReceipt(
            tableIndex: widget.tableIndex,
            orderIndex: widget.orderIndex,
            menuData: {
              ...menu,
              'quantity': quantity,
            },
          );
        } catch (e) {
          developer.log('Error adding menu: $e', name: 'EditOrderModal');
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

  @override
  Widget build(BuildContext context) {
    // Provider.watch를 통해 데이터 변경 시 UI 자동 갱신
    final table = context.watch<OrderProvider>().tables[widget.tableIndex];

    // orderIndex가 유효한지 확인
    if (widget.orderIndex < 0 || widget.orderIndex >= table.orders.length) {
      return const Center(child: Text("주문 정보를 찾을 수 없습니다."));
    }

    final order = table.orders[widget.orderIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showOrderHeader && widget.orderLabel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              widget.orderLabel!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: order.items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text("현재 주문 내역이 없습니다.")),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: order.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final dynamic item = order.items[index];
                    final String name =
                        item is Map ? item['name'] : item.toString();
                    final int quantity =
                        item is Map ? (item['quantity'] ?? 1) : 1;
                    final String rawStatus =
                        item is Map ? (item['status'] ?? 'ordered') : 'ordered';
                    // Normalize status to uppercase for consistent handling
                    final String status = rawStatus.toUpperCase();

                    final menuStatus = orderMenuStatusFromCode(status);
                    final nextStatuses = _getNextStatuses(status);

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
                      child: Column(
                        children: [
                          Row(
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

                              // 수량 표시
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "수량: $quantity",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // 수량 수정 버튼 (연필 아이콘) - 완료/취소됨 상태에서는 비활성화
                              InkWell(
                                onTap: (status == 'COMPLETED' ||
                                        status == 'CANCELED')
                                    ? null
                                    : () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              EditQuantityModal(
                                            itemName: name,
                                            currentQuantity: quantity,
                                            onConfirm: (newQuantity) async {
                                              await context
                                                  .read<OrderProvider>()
                                                  .updateMenuQuantity(
                                                    widget.tableIndex,
                                                    widget.orderIndex,
                                                    index,
                                                    newQuantity,
                                                  );
                                            },
                                          ),
                                        );
                                      },
                                child: Icon(
                                  Icons.edit,
                                  color: (status == 'COMPLETED' ||
                                          status == 'CANCELED')
                                      ? Colors.grey[300]
                                      : Colors.blue[600],
                                  size: 20,
                                ),
                              ),
                            ],
                          ),

                          // 상태와 상태 변경 버튼
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // 현재 상태 표시
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: menuStatus.bg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  menuStatus.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: menuStatus.fg,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // 상태 변경 버튼들
                              if (nextStatuses.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (var nextStatus in nextStatuses)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final provider = context
                                                .read<OrderProvider>();
                                            await provider.updateMenuStatus(
                                              widget.tableIndex,
                                              widget.orderIndex,
                                              index,
                                              nextStatus.code,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: nextStatus.fg,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            elevation: 0,
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          child: Text(
                                            _getShortStatusLabel(
                                                nextStatus.code),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              else
                                Text(
                                  '상태 변경 불가',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        if (widget.showActionButtons)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // 정산 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final provider = context.read<OrderProvider>();
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      final success = await provider.settleReceipt(widget.tableIndex, widget.orderIndex);

                      if (!mounted) return;
                      if (success) {
                        // 정산 완료 후 테이블 목록 새로고침
                        await provider.loadTables(widget.storeId ?? '');
                        // receipt_modal과 edit_order_modal을 모두 닫기
                        navigator.pop(); // edit_order_modal 닫기
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
                // 메뉴 추가하기 버튼
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openMenuSelectionModal,
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
          ),
      ],
    );
  }

  // 현재 상태에서 전환 가능한 다음 상태들을 반환
  List<OrderMenuStatus> _getNextStatuses(String currentStatus) {
    switch (currentStatus) {
      case 'ORDERED':
        // 접수 대기 -> 조리 중, 취소됨 가능
        return [
          OrderMenuStatus.cooking,
          OrderMenuStatus.canceled,
        ];
      case 'COOKING':
        // 조리 중 -> 완료, 취소됨 가능
        return [
          OrderMenuStatus.completed,
          OrderMenuStatus.canceled,
        ];
      case 'COMPLETED':
      case 'CANCELED':
        // 완료, 취소됨 -> 변경 불가
        return [];
      default:
        return [];
    }
  }

  // 상태 코드를 짧은 한글 레이블로 변환
  String _getShortStatusLabel(String statusCode) {
    return switch (statusCode) {
      'COOKING' => '조리',
      'COMPLETED' => '완료',
      'CANCELED' => '취소',
      _ => '변경',
    };
  }
}
