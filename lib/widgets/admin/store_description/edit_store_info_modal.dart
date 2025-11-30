import 'package:flutter/material.dart';
import 'package:table_order/models/admin/store_info.dart';

class EditStoreInfoModal extends StatefulWidget {
  final StoreInfoModel storeInfo;
  final Function(StoreInfoModel newInfo) onSubmit;

  const EditStoreInfoModal({
    super.key,
    required this.storeInfo,
    required this.onSubmit,
  });

  @override
  State<EditStoreInfoModal> createState() => _EditStoreInfoModalState();
}

class _EditStoreInfoModalState extends State<EditStoreInfoModal> {
  late TextEditingController _nameController;
  late TextEditingController _noticeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.storeInfo.storeName);
    _noticeController = TextEditingController(text: widget.storeInfo.notice);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noticeController.dispose();
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
        "가게정보 수정",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  labelText: "가게 이름",
                  labelStyle: labelStyle,
                  focusedBorder: focusedBorder,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _noticeController,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  labelText: "공지사항",
                  labelStyle: labelStyle,
                  focusedBorder: focusedBorder,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
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
          onPressed: () {
            // 수정된 내용을 담은 새 모델 생성
            final newInfo = StoreInfoModel(
              storeName: _nameController.text,
              notice: _noticeController.text,
            );
            widget.onSubmit(newInfo);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2d7ff9),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "저장",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
