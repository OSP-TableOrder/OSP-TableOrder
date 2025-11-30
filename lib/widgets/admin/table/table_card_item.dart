import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_order/models/admin/table_order_info.dart';

class TableCardItem extends StatefulWidget {
  final TableOrderInfo table;
  final VoidCallback onTap;

  const TableCardItem({super.key, required this.table, required this.onTap});

  @override
  State<TableCardItem> createState() => _TableCardItemState();
}

class _TableCardItemState extends State<TableCardItem> {
  // 오버레이 색상을 제어하기 위한 변수
  Color _overlayColor = Colors.transparent;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _updateBlinkState();
  }

  @override
  void didUpdateWidget(TableCardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateBlinkState();
  }

  void _updateBlinkState() {
    _blinkTimer?.cancel();
    if (!mounted) return;

    // 1. 신규 주문 깜빡임 (파란색 계열 오버레이)
    if (widget.table.hasNewOrder) {
      _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted) return;
        setState(() {
          // 투명도 0.7 <-> 0.3 반복
          _overlayColor = (_overlayColor == Colors.blue.withValues(alpha: 0.7))
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.blue.withValues(alpha: 0.7);
        });
      });
      return;
    }

    // 2. 직원 호출 깜빡임 (주황색 계열 오버레이)
    if (widget.table.hasCallRequest) {
      _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted) return;
        setState(() {
          // 투명도 0.7 <-> 0.3 반복
          _overlayColor =
              (_overlayColor == Colors.orange.withValues(alpha: 0.7))
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.7);
        });
      });
      return;
    }

    // 3. 알림이 없을 땐 오버레이 투명
    _overlayColor = Colors.transparent;
    setState(() {});
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 테이블의 모든 주문에서 메뉴 항목들 수집
    final allItems = <dynamic>[];
    for (final order in widget.table.orders) {
      allItems.addAll(order.items);
    }

    final bool hasOrder = allItems.isNotEmpty;
    final bool isNewOrder = widget.table.hasNewOrder;
    final bool isCallRequest = widget.table.hasCallRequest;
    final bool isHighlighted = widget.table.orderStatus == OrderStatus.ordered;

    // 카드의 기본 배경색 (깜빡이지 않음)
    final Color cardBgColor = isHighlighted ? const Color(0xff1e88ff) : Colors.white;
    final Color textColor = isHighlighted ? Colors.white : Colors.black87;
    final Color mutedTextColor = isHighlighted ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 170,
        height: 175, // 높이 확보
        // [중요] 여기에 padding을 주면 오버레이가 안쪽으로 밀리므로 제거
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xff1e88ff), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1층: 내용물 (Padding은 여기에 적용)
            Padding(
              padding: const EdgeInsets.all(10), // 내부 여백
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 테이블 이름
                  Text(
                    widget.table.tableName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.table.orderStatus == OrderStatus.ordered
                          ? Colors.white
                          : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // 메뉴 목록
                  Expanded(
                    child: hasOrder
                        ? _buildOrderContent(allItems, textColor, mutedTextColor)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // 2층: 신규 주문 오버레이 (전체 덮기 + 깜빡임)
            if (isNewOrder)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    color: _overlayColor,
                    borderRadius: BorderRadius.circular(9), // 테두리 두께 고려
                  ),
                  child: _buildOverlayText("상품\n주문"),
                ),
              ),

            // 3층: 직원 호출 오버레이 (전체 덮기 + 깜빡임)
            if (isCallRequest)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    color: _overlayColor,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: _buildOverlayText("직원\n호출"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 오버레이 텍스트 위젯
  Widget _buildOverlayText(String text) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              offset: Offset(0, 2),
              blurRadius: 4.0,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  // 메뉴 리스트 내용물
  Widget _buildOrderContent(
    List<dynamic> items,
    Color textColor,
    Color mutedTextColor,
  ) {
    final int displayCount = items.length > 3 ? 3 : items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < displayCount; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 메뉴명
                      Expanded(
                        child: Text(
                          _getItemName(items[i]),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      ),
                      // 수량
                      Text(
                        "x${_getItemQty(items[i])}",
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              if (items.length > 3)
                Text(
                  "...",
                  style: TextStyle(fontSize: 13, color: mutedTextColor),
                ),
            ],
          ),
        ),

        // 총 가격
        Align(
          alignment: Alignment.bottomRight,
          child: Text(
            "${widget.table.totalPrice}원",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  String _getItemName(dynamic item) {
    if (item is Map) return item['name'] ?? '';
    return item.toString();
  }

  int _getItemQty(dynamic item) {
    if (item is Map) return item['quantity'] ?? 1;
    return 1;
  }
}
