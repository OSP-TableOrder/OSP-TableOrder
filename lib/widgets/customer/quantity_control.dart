import 'package:flutter/material.dart';

class QuantityControl extends StatelessWidget {
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const QuantityControl({
    super.key,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, size: 20),
            onPressed: onDecrement,
            padding: EdgeInsets.zero,
          ),
          Container(width: 1, height: 20, color: Colors.grey[400]),
          IconButton(
            icon: Icon(Icons.add, size: 20),
            onPressed: onIncrement,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
