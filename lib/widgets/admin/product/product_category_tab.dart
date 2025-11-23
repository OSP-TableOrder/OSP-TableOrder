import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/provider/admin/category_provider.dart';

class ProductCategoryTab extends StatelessWidget {
  const ProductCategoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: const Text("전체"),
              selected: categoryProvider.selectedCategoryIndex == 0,
              showCheckmark: false,
              selectedColor: Colors.white,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: categoryProvider.selectedCategoryIndex == 0
                    ? const Color(0xff2d7ff9)
                    : Colors.grey.shade400,
                width: 1.4,
              ),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: categoryProvider.selectedCategoryIndex == 0
                    ? const Color(0xff2d7ff9)
                    : Colors.black87,
              ),
              onSelected: (_) => categoryProvider.selectCategory(0),
            ),
          ),

          for (int i = 0; i < categories.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(categories[i].name),
                selected: categoryProvider.selectedCategoryIndex == i + 1,
                showCheckmark: false,
                selectedColor: Colors.white,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: categoryProvider.selectedCategoryIndex == i + 1
                      ? const Color(0xff2d7ff9)
                      : Colors.grey.shade400,
                  width: 1.4,
                ),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: categoryProvider.selectedCategoryIndex == i + 1
                      ? const Color(0xff2d7ff9)
                      : Colors.black87,
                ),
                onSelected: (_) => categoryProvider.selectCategory(i + 1),
              ),
            ),
        ],
      ),
    );
  }
}
