import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_order/models/admin/table_info.dart';

class TableCard extends StatefulWidget {
  final TableInfo table;
  final VoidCallback onTap;

  const TableCard({super.key, required this.table, required this.onTap});

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> {
  Color currentColor = Colors.white;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _updateBlinkState();
  }

  @override
  void didUpdateWidget(TableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateBlinkState();
  }

  void _updateBlinkState() {
    _blinkTimer?.cancel();

    if (!mounted) return;

    // 신규 주문 깜빡임
    if (widget.table.hasNewOrder) {
      _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted) return;
        setState(() {
          currentColor =
              (currentColor == const Color.fromARGB(255, 25, 109, 204))
              ? const Color(0xff1e88ff)
              : const Color.fromARGB(255, 25, 109, 204);
        });
      });
      return;
    }

    // 직원 호출 깜빡임
    if (widget.table.hasCallRequest) {
      _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted) return;
        setState(() {
          currentColor =
              (currentColor == const Color.fromARGB(255, 205, 132, 17))
              ? const Color.fromARGB(255, 241, 156, 19)
              : const Color.fromARGB(255, 205, 132, 17);
        });
      });
      return;
    }

    // 깜빡임 종료 → 원래 주문 상태 복원
    if (widget.table.orderStatus == OrderStatus.ordered) {
      currentColor = const Color(0xff1e88ff);
    } else {
      currentColor = Colors.white;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasOrder = widget.table.items.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 170,
        height: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xff1e88ff), width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.table.tableName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: widget.table.orderStatus == OrderStatus.ordered
                    ? Colors.white
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: hasOrder ? _buildOrderContent() : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderContent() {
    final items = widget.table.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length && i < 3; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  items[i],
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
              const Text(
                "1",
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
            ],
          ),

        if (items.length > 3)
          const Text(
            "...",
            style: TextStyle(fontSize: 13, color: Colors.white),
          ),

        const Spacer(),

        Align(
          alignment: Alignment.bottomRight,
          child: Text(
            "${widget.table.totalPrice}원",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
