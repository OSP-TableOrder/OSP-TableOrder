import 'package:flutter/material.dart';

class EditQuantityModal extends StatefulWidget {
  final String itemName;
  final int currentQuantity;
  final ValueChanged<int> onConfirm;

  const EditQuantityModal({
    super.key,
    required this.itemName,
    required this.currentQuantity,
    required this.onConfirm,
  });

  @override
  State<EditQuantityModal> createState() => _EditQuantityModalState();
}

class _EditQuantityModalState extends State<EditQuantityModal> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.currentQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        "수량 수정",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("'${widget.itemName}' 수량을 수정하세요."),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _quantity > 1
                    ? () {
                        setState(() {
                          _quantity--;
                        });
                      }
                    : null, // 1개일 때는 비활성화
                icon: const Icon(Icons.remove_circle_outline),
                color: _quantity > 1 ? Colors.black : Colors.grey,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "$_quantity",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _quantity++;
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.black,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("닫기", style: TextStyle(color: Colors.grey)),
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
            widget.onConfirm(_quantity);
            Navigator.of(context).pop();
          },
          child: const Text("확인"),
        ),
      ],
    );
  }
}
