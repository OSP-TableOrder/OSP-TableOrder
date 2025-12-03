import 'dart:async';
import 'package:flutter/material.dart';

Future<bool?> showConfirmModal(
  BuildContext context, {
  required String title,
  String? description,
  String cancelText = '취소',
  String actionText = '확인',
  Future<void> Function()? onActionAsync,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierLabel: 'confirm',
    barrierDismissible: true,
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, _, __) {
      bool isProcessing = false;

      return Center(
        child: Material(
          color: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setState) {
              Future<void> handleAction() async {
                setState(() => isProcessing = true);
                final dialogContext = context;
                try {
                  if (!dialogContext.mounted) return;

                  // 모달 즉시 닫기
                  Navigator.of(dialogContext).pop(true);

                  // 백그라운드에서 비동기 작업 실행
                  if (onActionAsync != null) {
                    unawaited(onActionAsync());
                  }
                } finally {
                  if (dialogContext.mounted) {
                    setState(() => isProcessing = false);
                  }
                }
              }

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
                    maxWidth: 360,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 모달 제목
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        // 모달 내용
                        if (description != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // 모달 하단 버튼
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 취소
                            TextButton(
                              onPressed: isProcessing
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              child: Text(
                                cancelText,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            // 확인
                            TextButton(
                              onPressed: isProcessing ? null : handleAction,
                              child: Text(
                                isProcessing ? '처리 중...' : actionText,
                                style: const TextStyle(color: Colors.blue),
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
