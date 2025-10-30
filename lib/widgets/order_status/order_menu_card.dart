import 'package:flutter/material.dart';

import '../../models/order_status/order_menu_status.dart';
import '../../models/order_status/order_menu.dart';
import '../../widgets/order_status/order_status_tag.dart';
import '../../utils/won_formatter.dart';

class OrderMenuCard extends StatelessWidget {
  final OrderMenu menu;
  final VoidCallback? onTapDelete;

  const OrderMenuCard({super.key, required this.menu, this.onTapDelete});

  @override
  Widget build(BuildContext context) {
    final isCanceled = menu.status == OrderMenuStatus.canceled;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x11000000)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            spreadRadius: 1,
            offset: Offset(0, 2),
            color: Color(0x14000000),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메뉴 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: menu.menuImageUrl != null
                  ? Image.network(menu.menuImageUrl!, fit: BoxFit.cover)
                  : const ColoredBox(color: Color(0xFFF6F7F9)),
            ),
          ),
          const SizedBox(width: 14),

          // 메뉴 정보
          Expanded(
            child: Opacity(
              opacity: isCanceled ? 0.4 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 메뉴명
                  Text(
                    menu.menuName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 메뉴 설명
                  if (menu.menuDescription != null)
                    Text(
                      menu.menuDescription!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // 메뉴 단품 가격 및 주문 개수
                  Text(
                    '${formatWon(menu.menuPrice)}원 × ${menu.quantity}개',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 주문 상태
                  OrderStatusTag(status: menu.status),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 메뉴 취소가 가능한 접수 대기 상태인 경우 삭제 버튼 표시
          if (menu.isCancelable && onTapDelete != null)
            InkWell(
              onTap: onTapDelete,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.delete_outline, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
