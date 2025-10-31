import 'package:flutter/material.dart';

/// 사용 예:
/// final ok = await showCallStaffDialog(
///   context,
///   receiptId: "영수증 번호",
///   onSubmit: (id, msg, items) async { /* API 호출 */ },
/// );
Future<bool?> showCallStaffDialog(
  BuildContext context, {
  required String receiptId,
  List<String> initialItems = const [
    "앞접시",
    "휴지",
    "물티슈",
    "숟가락",
    "젓가락",
    "소주컵",
    "종이컵",
  ],
  required Future<void> Function(
    String receiptId,
    String message,
    List<String> items,
  )
  onSubmit,
}) {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final Set<String> selected = <String>{};

  bool isProcessing = false;
  bool messageEditedManually = false;
  String lastAutoMessage = "";

  const double kDialogMaxWidth = 450;
  const double kOuterHPad = 24;
  const double kOuterVPad = 24;
  const EdgeInsets kInnerPadding = EdgeInsets.fromLTRB(26, 26, 26, 20);
  const double kBtnHeight = 44;

  const Color kChipBg = Color(0xFFECECEC);
  const Color kChipSelected = Color(0xFF6299FE);
  const Color kHint = Color(0xFF7E7E7E);
  const Color kText = Color(0xFF333333);

  String buildAutoMessage() =>
      selected.isEmpty ? "" : "${selected.join(", ")} 주세요!";

  void toggleItem(String text, StateSetter setState) {
    if (selected.contains(text)) {
      selected.remove(text);
    } else {
      selected.add(text);
    }

    // 사용자가 직접 수정하지 않았거나, 버튼으로 생성된 문구 그대로라면 자동 갱신
    if (!messageEditedManually || controller.text == lastAutoMessage) {
      lastAutoMessage = buildAutoMessage();
      controller.text = lastAutoMessage;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
      messageEditedManually = false;
    }
    setState(() {});
  }

  Future<void> submit(StateSetter setState, BuildContext dialogContext) async {
    final msg = controller.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(
        dialogContext,
      ).showSnackBar(const SnackBar(content: Text("요청 메시지를 입력해주세요.")));
      focusNode.requestFocus();
      return;
    }
    if (isProcessing) return;

    setState(() => isProcessing = true);
    try {
      await onSubmit(receiptId, msg, selected.toList(growable: false));
      if (!dialogContext.mounted) return;

      ScaffoldMessenger.of(
        dialogContext,
      ).showSnackBar(const SnackBar(content: Text("호출 요청이 전송되었습니다.")));
      Navigator.of(dialogContext).pop(true);
    } catch (_) {
      if (!dialogContext.mounted) return;
      ScaffoldMessenger.of(
        dialogContext,
      ).showSnackBar(const SnackBar(content: Text("호출 요청 중 오류가 발생했습니다.")));
      setState(() => isProcessing = false);
    }
  }

  Widget buildTitle() => const Text(
    "직원 호출하기",
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
  );

  Widget buildTagChips(StateSetter setState) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final text in initialItems)
        ChoiceChip(
          label: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: selected.contains(text)
                  ? Colors.white
                  : const Color(0xFF555555),
            ),
          ),
          selected: selected.contains(text),
          onSelected: (_) => toggleItem(text, setState),
          showCheckmark: false,
          selectedColor: kChipSelected,
          backgroundColor: kChipBg,
          side: BorderSide.none,
          shape: const StadiumBorder(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
    ],
  );

  Widget buildTextField(StateSetter setState, BuildContext dialogContext) =>
      TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => submit(setState, dialogContext),
        onChanged: (v) => messageEditedManually = (v != lastAutoMessage),
        decoration: const InputDecoration(
          hintText: "요청사항을 적어주세요!",
          isDense: true,
          filled: true,
          fillColor: kChipBg,
          hintStyle: TextStyle(color: kHint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        style: const TextStyle(fontSize: 14, color: kText),
        maxLines: 1,
      );

  Widget buildActions(StateSetter setState, BuildContext dialogContext) => Row(
    children: [
      Expanded(
        child: SizedBox(
          height: kBtnHeight,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.transparent),
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
            ),
            onPressed: isProcessing
                ? null
                : () => Navigator.of(dialogContext).pop(false),
            child: const Text("취소", textAlign: TextAlign.center),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: SizedBox(
          height: kBtnHeight,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.transparent),
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
            ),
            onPressed: isProcessing
                ? null
                : () => submit(setState, dialogContext),
            child: isProcessing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("저장", textAlign: TextAlign.center),
          ),
        ),
      ),
    ],
  );

  return showGeneralDialog<bool>(
    context: context,
    barrierLabel: 'call-staff',
    barrierDismissible: true,
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, _, __) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: StatefulBuilder(
            builder: (dialogContext, setState) => Dialog(
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: kOuterHPad,
                vertical: kOuterVPad,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 280,
                  maxWidth: kDialogMaxWidth,
                ),
                child: SingleChildScrollView(
                  padding: kInnerPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildTitle(),
                      const SizedBox(height: 26),
                      buildTagChips(setState),
                      const SizedBox(height: 18),
                      buildTextField(setState, dialogContext),
                      const SizedBox(height: 18),
                      buildActions(setState, dialogContext),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: .98, end: 1).animate(anim),
          child: child,
        ),
      );
    },
  );
}
