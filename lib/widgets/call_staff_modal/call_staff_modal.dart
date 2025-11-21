import 'package:flutter/material.dart';

/// 사용 예:
/// final ok = await showCallStaffDialog(
///   context,
///   receiptId: "영수증 번호",
///   onSubmit: (id, msg, items) async { /* API 호출 */ },
/// );
Future<bool?> showCallStaffDialog(
  BuildContext context, {
  // 영수증 ID
  required String receiptId,
  // 미리 만들어진 요청사항
  List<String> items = const ["앞접시", "휴지", "물티슈", "숟가락", "젓가락", "소주컵", "종이컵"],
  // API 호출
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

  String autoMessage() => selected.isEmpty ? "" : "${selected.join(", ")} 주세요!";

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
            builder: (dialogContext, setState) {
              return Dialog(
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 280,
                    maxWidth: 450,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(26, 26, 26, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 모달 제목
                        const Text(
                          "직원 호출하기",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 26),

                        // 칩 목록
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final text in items)
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
                                onSelected: (_) => {
                                  (text) {
                                    if (selected.contains(text)) {
                                      selected.remove(text);
                                    } else {
                                      selected.add(text);
                                    }
                                    if (!messageEditedManually ||
                                        controller.text == lastAutoMessage) {
                                      lastAutoMessage = autoMessage();
                                      controller.text = lastAutoMessage;
                                      controller.selection =
                                          TextSelection.collapsed(
                                            offset: controller.text.length,
                                          );
                                      messageEditedManually = false;
                                    }
                                    setState(() {});
                                  },
                                },
                                showCheckmark: false,
                                selectedColor: const Color(0xFF6299FE),
                                backgroundColor: const Color(0xFFECECEC),
                                side: BorderSide.none,
                                shape: const StadiumBorder(),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // 요청 사항 입력 필드
                        TextField(
                          controller: controller,
                          focusNode: focusNode,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => submit(setState, dialogContext),
                          onChanged: (v) =>
                              messageEditedManually = (v != lastAutoMessage),
                          decoration: const InputDecoration(
                            hintText: "요청사항을 적어주세요!",
                            isDense: true,
                            filled: true,
                            fillColor: Color(0xFFECECEC),
                            hintStyle: TextStyle(color: Color(0xFF7E7E7E)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            // 취소 버튼
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.transparent,
                                    ),
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                  ),
                                  onPressed: isProcessing
                                      ? null
                                      : () => Navigator.of(
                                          dialogContext,
                                        ).pop(false),
                                  child: const Text(
                                    "취소",
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // 저장 버튼
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.transparent,
                                    ),
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
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "저장",
                                          textAlign: TextAlign.center,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: .98, end: 1).animate(anim),
        child: child,
      ),
    ),
  );
}
