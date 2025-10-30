import 'package:flutter/material.dart';

import '../../models/order_status/order_menu_status.dart';

class OrderStatusTag extends StatelessWidget {
  final OrderMenuStatus status;
  const OrderStatusTag({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          color: status.fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
