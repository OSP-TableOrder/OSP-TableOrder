import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/models/admin/product.dart';
import 'package:table_order/provider/admin/category_provider.dart';

class ProductAddModal extends StatefulWidget {
  final Function(Product) onSubmit;

  const ProductAddModal({super.key, required this.onSubmit});

  @override
  State<ProductAddModal> createState() => _ProductAddModalState();
}

class _ProductAddModalState extends State<ProductAddModal> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  int stock = 0;
  bool isSoldOut = false;
  bool isActive = true;

  String? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        "상품 추가",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedCategoryId,
              items: categories
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedCategoryId = v),
              decoration: const InputDecoration(labelText: "카테고리"),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "상품명"),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "가격"),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("재고"),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (stock > 0) stock--;
                        });
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text("$stock"),
                    IconButton(
                      onPressed: () => setState(() => stock++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("품절 여부"),
                Switch(
                  value: isSoldOut,
                  onChanged: (v) => setState(() => isSoldOut = v),

                  activeTrackColor: const Color(0xff2d7ff9),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.black26,
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("노출 여부"),
                Switch(
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),

                  activeTrackColor: const Color(0xff2d7ff9),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.black26,
                ),
              ],
            ),

            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "상세 설명"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (selectedCategoryId == null) return;

            final newProduct = Product(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              categoryId: selectedCategoryId!,
              name: nameController.text.trim(),
              price: priceController.text.trim(),
              stock: stock,
              isSoldOut: isSoldOut,
              isActive: isActive,
              description: descriptionController.text.trim(),
            );

            widget.onSubmit(newProduct);
            Navigator.pop(context);
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2d7ff9),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          child: const Text("추가"),
        ),
      ],
    );
  }
}
