import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/models/admin/product.dart';
import 'package:table_order/provider/admin/category_provider.dart';

class ProductEditModal extends StatefulWidget {
  final Product product; // Product 객체 그대로 받음
  final Function(Product) onSubmit; // 수정된 Product 반환

  const ProductEditModal({
    super.key,
    required this.product,
    required this.onSubmit,
  });

  @override
  State<ProductEditModal> createState() => _ProductEditModalState();
}

class _ProductEditModalState extends State<ProductEditModal> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;

  late int stock;
  late bool isSoldOut;
  late bool isActive;

  late String selectedCategoryId;

  final labelStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(text: widget.product.price);
    descriptionController = TextEditingController(
      text: widget.product.description,
    );

    stock = widget.product.stock;
    isSoldOut = widget.product.isSoldOut;
    isActive = widget.product.isActive;
    selectedCategoryId = widget.product.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        "상품 수정",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),

      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedCategoryId,
              items: categoryProvider.categories
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedCategoryId = v!),
              decoration: InputDecoration(
                labelText: "카테고리",
                labelStyle: labelStyle,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "상품명",
                labelStyle: labelStyle,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "가격",
                labelStyle: labelStyle,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("재고 수량", style: labelStyle),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() {
                          if (stock > 0) stock--;
                        });
                      },
                    ),
                    Text(
                      "$stock",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => stock++),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("품절 여부", style: labelStyle),
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
                Text("노출 여부", style: labelStyle),
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
              decoration: InputDecoration(
                labelText: "상세 설명",
                labelStyle: labelStyle,
              ),
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
            final updatedProduct = Product(
              id: widget.product.id,
              name: nameController.text.trim(),
              price: priceController.text.trim(),
              stock: stock,
              isSoldOut: isSoldOut,
              isActive: isActive,
              description: descriptionController.text.trim(),
              categoryId: selectedCategoryId,
            );

            widget.onSubmit(updatedProduct);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2d7ff9),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("수정"),
        ),
      ],
    );
  }
}
