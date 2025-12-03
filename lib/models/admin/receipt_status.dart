/// 영수증(Receipt) 상태 열거형
/// Firestore의 receipt status 필드와 매핑
enum ReceiptStatus {
  /// 정산 대기 중
  unpaid('unpaid'),

  /// 정산 완료
  paid('paid');

  final String value;

  const ReceiptStatus(this.value);

  /// String 값을 ReceiptStatus로 변환
  static ReceiptStatus fromString(String? value) {
    if (value == null) return ReceiptStatus.unpaid;

    return ReceiptStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ReceiptStatus.unpaid,
    );
  }

  /// 한글 라벨 반환
  String get label {
    switch (this) {
      case ReceiptStatus.unpaid:
        return '미정산';
      case ReceiptStatus.paid:
        return '정산완료';
    }
  }

  /// 사용자 친화적 표시
  String get displayName => label;
}
