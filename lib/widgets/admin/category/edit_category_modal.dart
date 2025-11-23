import 'package:flutter/material.dart';

class EditCategoryModal extends StatefulWidget {
  final String initialName;
  final bool initialActive;
  final Function(String, bool) onSubmit;

  const EditCategoryModal({
    super.key,
    required this.initialName,
    required this.initialActive,
    required this.onSubmit,
  });

  @override
  State<EditCategoryModal> createState() => _EditCategoryModalState();
}

class _EditCategoryModalState extends State<EditCategoryModal> {
  late TextEditingController controller;
  late bool isActive;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialName);
    isActive = widget.initialActive;
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);

    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        "카테고리 수정",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: "카테고리 이름",
              labelStyle: labelStyle,
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xff2d7ff9), width: 2),
              ),
            ),
            style: labelStyle,
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("노출 여부", style: labelStyle),

              Switch(
                value: isActive,
                onChanged: (v) {
                  setState(() {
                    isActive = v;
                  });
                },

                activeTrackColor: const Color(0xff2d7ff9),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.black26,
              ),
            ],
          ),
        ],
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
            widget.onSubmit(controller.text.trim(), isActive);
            Navigator.pop(context);
          },
          child: const Text(
            "수정",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
