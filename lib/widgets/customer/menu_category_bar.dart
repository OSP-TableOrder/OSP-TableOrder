import 'package:flutter/material.dart';

class MenuCategoryBar extends StatelessWidget {
  final List<String?> categoryIds;
  final String? selectedCategoryId;
  final Map<String?, String> categoryLabels;
  final ValueChanged<String?> onCategoryTap;

  const MenuCategoryBar({
    super.key,
    required this.categoryIds,
    required this.selectedCategoryId,
    required this.categoryLabels,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categoryIds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final categoryId = categoryIds[index];
            final label =
                categoryLabels[categoryId] ?? categoryId ?? '기타';
            final isSelected = categoryId == selectedCategoryId;

            return GestureDetector(
              onTap: () => onCategoryTap(categoryId),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFDCE6FF)
                      : const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3B66F5)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
