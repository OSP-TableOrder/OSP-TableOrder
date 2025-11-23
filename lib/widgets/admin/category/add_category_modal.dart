import 'package:flutter/material.dart';

class AddCategoryModal extends StatefulWidget {
  final Function(String) onSubmit;

  const AddCategoryModal({super.key, required this.onSubmit});

  @override
  State<AddCategoryModal> createState() => _AddCategoryModalState();
}

class _AddCategoryModalState extends State<AddCategoryModal> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);

    return AlertDialog(
      backgroundColor: Colors.white,

      title: const Text(
        "카테고리 추가",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),

      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: "카테고리 이름",
          labelStyle: labelStyle,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xff2d7ff9), width: 2),
          ),
        ),
        style: labelStyle,
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "취소",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2d7ff9),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              widget.onSubmit(controller.text.trim());
            }
            Navigator.pop(context);
          },
          child: const Text(
            "추가",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
