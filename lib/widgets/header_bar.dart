import 'package:flutter/material.dart';

class HeaderBar extends StatelessWidget {
  final String title;

  /// 왼쪽/오른쪽에 들어갈 아이템 (Text, Icon, Row 모두 가능)
  final Widget? leftItem;
  final Widget? rightItem;

  const HeaderBar({
    super.key,
    required this.title,
    this.leftItem,
    this.rightItem,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.black12),
          ),
        ),
        child: Row(
          children: [
            // 왼쪽
            leftItem ?? const SizedBox(width: 40),

            // 가운데(항상 중앙 유지)
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 오른쪽
            rightItem ?? const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}
