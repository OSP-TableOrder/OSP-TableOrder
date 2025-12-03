import 'package:flutter/material.dart';

import 'package:table_order/models/customer/store.dart';
import 'package:table_order/widgets/customer/measured_size.dart';

class StoreInfoHeader extends StatelessWidget {
  final Store? store;
  final String? tableName;
  final bool isNoticeExpanded;
  final VoidCallback onToggleNotice;
  final ValueChanged<double>? onHeight;

  const StoreInfoHeader({
    super.key,
    required this.store,
    required this.tableName,
    required this.isNoticeExpanded,
    required this.onToggleNotice,
    this.onHeight,
  });

  @override
  Widget build(BuildContext context) {
    final storeName = store?.name ?? '가게 정보를 불러오는 중입니다';
    final tableText =
        (tableName == null || tableName!.isEmpty) ? 'null' : tableName!;
    final notice = (store?.notice ?? '').trim();
    final hasNotice = notice.isNotEmpty;
    final availableWidth = MediaQuery.of(context).size.width - 32;
    final tableMaxWidth = availableWidth * 0.4;

    Widget content = Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '멤버도 QR 찍고 함께 주문해요',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 4,
                fit: FlexFit.loose,
                child: Align(
                  alignment: Alignment.topRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: tableMaxWidth),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event_seat_outlined,
                            size: 18,
                            color: Color(0xFF4A5161),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              tableText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasNotice) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onToggleNotice,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.campaign_outlined,
                      color: Color(0xFF3B66F5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notice,
                        maxLines: isNoticeExpanded ? null : 2,
                        overflow: isNoticeExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Icon(
                          isNoticeExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF3B66F5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onHeight != null) {
      content = MeasuredSize(
        onHeight: onHeight!,
        child: content,
      );
    }

    return content;
  }
}
