import 'package:flutter/material.dart';

class DeleteCategoryModal extends StatelessWidget {
  final String categoryName;
  final VoidCallback onDelete;

  const DeleteCategoryModal({
    super.key,
    required this.categoryName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        "삭제",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: Text("\"$categoryName\" 카테고리를 삭제하시겠습니까?"),
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
          child: const Text("삭제"),
        ),
      ],
    );
  }
}
