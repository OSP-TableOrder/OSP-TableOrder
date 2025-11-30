import 'package:flutter/material.dart';

class CancelOrderModal extends StatefulWidget {
  final String itemName;
  final int currentQty;
  final Function(int) onConfirm; // 취소 확정 시 실행할 함수

  const CancelOrderModal({
    super.key,
    required this.itemName,
    required this.currentQty,
    required this.onConfirm,
  });

  @override
  State<CancelOrderModal> createState() => _CancelOrderModalState();
}

class _CancelOrderModalState extends State<CancelOrderModal> {
  int _cancelQty = 1; // 취소할 수량 상태 관리

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        "메뉴 취소",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("'${widget.itemName}' 메뉴를 몇 개 취소하시겠습니까?"),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _cancelQty > 1
                    ? () {
                        setState(() {
                          _cancelQty--;
                        });
                      }
                    : null, // 1개일 때는 비활성화
                icon: const Icon(Icons.remove_circle_outline),
                color: _cancelQty > 1 ? Colors.black : Colors.grey,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "$_cancelQty",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              IconButton(
                onPressed: _cancelQty < widget.currentQty
                    ? () {
                        setState(() {
                          _cancelQty++;
                        });
                      }
                    : null, // 최대 수량일 때는 비활성화
                icon: const Icon(Icons.add_circle_outline),
                color: _cancelQty < widget.currentQty
                    ? Colors.black
                    : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _cancelQty == widget.currentQty
                ? "*전체 삭제됩니다."
                : "*${widget.currentQty - _cancelQty}개 남습니다.",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            widget.onConfirm(_cancelQty); // 부모에게 선택된 수량 전달
            Navigator.of(context).pop(); // 다이얼로그 닫기
          },
          child: const Text("취소 적용"),
        ),
      ],
    );
  }
}
