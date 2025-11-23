import 'package:flutter/material.dart';
import 'package:table_order/widgets/admin/side_menu_drawer/side_menu_item.dart';

class SideMenuDrawer extends StatelessWidget {
  final Function(String) onSelectMenu;
  const SideMenuDrawer({super.key, required this.onSelectMenu});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Material(
        elevation: 8,
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.only(left: 16, top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '토스플레이스 테이블오더',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              MenuItem(
                title: '홈',
                fontSize: 14,
                onTap: () => onSelectMenu('홈'),
              ),

              MenuItem(
                title: '카테고리 수정',
                fontSize: 14,
                onTap: () => onSelectMenu('카테고리 수정'),
              ),

              MenuItem(
                title: '상품 수정',
                fontSize: 14,
                onTap: () => onSelectMenu('상품 수정'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
