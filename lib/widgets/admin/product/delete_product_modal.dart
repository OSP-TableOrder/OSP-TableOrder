import 'package:flutter/material.dart';

class DeleteProductModal extends StatelessWidget {
  final String productName;
  final VoidCallback onDelete;

  const DeleteProductModal({
    super.key,
    required this.productName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        "상품 삭제",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: Text("\"$productName\" 상품을 삭제하시겠습니까?"),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소", style: TextStyle(color: Colors.grey)),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            onDelete();
            Navigator.pop(context);
          },
          child: const Text(
            "삭제",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
