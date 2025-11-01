import 'package:flutter/material.dart';

enum OrderMenuStatus { ordered, cooking, completed, canceled }

extension OrderMenuStatusX on OrderMenuStatus {
  String get code => switch (this) {
    OrderMenuStatus.ordered => 'ORDERED',
    OrderMenuStatus.cooking => 'COOKING',
    OrderMenuStatus.completed => 'COMPLETED',
    OrderMenuStatus.canceled => 'CANCELED',
  };

  String get label => switch (this) {
    OrderMenuStatus.ordered => '접수 대기',
    OrderMenuStatus.cooking => '조리 중',
    OrderMenuStatus.completed => '완료',
    OrderMenuStatus.canceled => '취소됨',
  };

  bool get isCancelable => this == OrderMenuStatus.ordered;

  Color get bg => switch (this) {
    OrderMenuStatus.ordered => const Color(0xFFFFF1D7),
    OrderMenuStatus.cooking => const Color(0xFFE7F0FF),
    OrderMenuStatus.completed => const Color(0xFFEFFBEA),
    OrderMenuStatus.canceled => const Color(0xFFFDEBEC),
  };

  Color get fg => switch (this) {
    OrderMenuStatus.ordered => const Color(0xFF9C6B00),
    OrderMenuStatus.cooking => const Color(0xFF004BBD),
    OrderMenuStatus.completed => const Color(0xFF1D7A22),
    OrderMenuStatus.canceled => const Color(0xFFD43C3C),
  };
}
