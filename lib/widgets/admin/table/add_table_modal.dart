import 'package:flutter/material.dart';

class AddTableModal extends StatefulWidget {
  final Function(String name) onSubmit;

  const AddTableModal({super.key, required this.onSubmit});

  @override
  State<AddTableModal> createState() => _AddTableModalState();
}

class _AddTableModalState extends State<AddTableModal> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    const focusedBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xff2d7ff9), width: 2),
    );

    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        "테이블 추가",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            labelText: "테이블 이름 (예: 5번 테이블)",
            labelStyle: labelStyle,
            focusedBorder: focusedBorder,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onSubmit(_controller.text);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2d7ff9),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "추가",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
