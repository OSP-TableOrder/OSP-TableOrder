import 'package:flutter/material.dart';

import 'package:table_order/utils/won_formatter.dart';
import 'package:table_order/models/order_status/order_menu_status.dart';
import 'package:table_order/models/order_status/order_menu.dart';
import 'package:table_order/widgets/order_status/order_status_tag.dart';

class OrderMenuCard extends StatelessWidget {
  final OrderMenu orderMenu;
  final VoidCallback? onTapDelete;

  const OrderMenuCard({super.key, required this.orderMenu, this.onTapDelete});

  @override
  Widget build(BuildContext context) {
    final isCanceled = orderMenu.status == OrderMenuStatus.canceled;

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 메뉴 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: orderMenu.menu.imageUrl != null
                  ? Image.network(
                      orderMenu.menu.imageUrl!,
                      fit: BoxFit.cover,
                      cacheWidth: 144,
                      cacheHeight: 144,
                    )
                  : const ColoredBox(color: Color(0xFFF6F7F9)),
            ),
          ),
          const SizedBox(width: 14),

          // 메뉴 정보
          Expanded(
            child: AnimatedOpacity(
              opacity: isCanceled ? 0.4 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 메뉴명
                  Text(
                    orderMenu.menu.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 메뉴 설명
                  if (orderMenu.menu.description != null)
                    Text(
                      orderMenu.menu.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                  const SizedBox(height: 4),

                  // 메뉴 단품 가격 및 주문 개수
                  Text(
                    '${formatWon(orderMenu.menu.price)}원 × ${orderMenu.quantity}개',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 주문 상태
                  OrderStatusTag(status: orderMenu.status),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 메뉴 취소가 가능한 접수 대기 상태인 경우 삭제 버튼 표시
          if (orderMenu.isCancelable && onTapDelete != null)
            SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: IconButton(
                  onPressed: onTapDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  splashRadius: 18,
                  tooltip: '주문 취소',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
