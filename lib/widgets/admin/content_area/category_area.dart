import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/provider/admin/category_provider.dart';
import 'package:table_order/widgets/admin/category/add_category_modal.dart';
import 'package:table_order/widgets/admin/category/category_list.item.dart';
import 'package:table_order/widgets/admin/category/edit_category_modal.dart';
import 'package:table_order/widgets/admin/category/delete_category_modal.dart';

class CategoryArea extends StatefulWidget {
  const CategoryArea({super.key});

  @override
  State<CategoryArea> createState() => _CategoryAreaState();
}

class _CategoryAreaState extends State<CategoryArea> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryProvider>().loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final categories = provider.categories;

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xffe9eef3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "카테고리",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddCategoryModal(
                      onSubmit: (name) {
                        provider.addCategory(name);
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2d7ff9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("+ 카테고리 추가"),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 카테고리 리스트
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final item = categories[i];

                return CategoryListItem(
                  name: item.name,
                  active: item.active,
                  onEdit: () {
                    showDialog(
                      context: context,
                      builder: (_) => EditCategoryModal(
                        initialName: item.name,
                        initialActive: item.active,
                        onSubmit: (newName, active) {
                          provider.updateCategory(item.id, newName, active);
                        },
                      ),
                    );
                  },
                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (_) => DeleteCategoryModal(
                        categoryName: item.name,
                        onDelete: () {
                          provider.deleteCategory(item.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
