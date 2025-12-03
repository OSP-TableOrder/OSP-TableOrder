/// 직원 호출 요청(Call Request) 상태 열거형
/// Firestore의 call request status 필드와 매핑
enum CallRequestStatus {
  /// 호출 대기 중 (처리 안 됨)
  pending('pending'),

  /// 호출 해결됨 (직원이 확인함)
  resolved('resolved');

  final String value;

  const CallRequestStatus(this.value);

  /// String 값을 CallRequestStatus로 변환
  static CallRequestStatus fromString(String? value) {
    if (value == null) return CallRequestStatus.pending;

    return CallRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CallRequestStatus.pending,
    );
  }

  /// 한글 라벨 반환
  String get label {
    switch (this) {
      case CallRequestStatus.pending:
        return '대기 중';
      case CallRequestStatus.resolved:
        return '해결됨';
    }
  }

  /// 사용자 친화적 표시
  String get displayName => label;

  /// 해결된 상태인지 확인
  bool get isResolved => this == CallRequestStatus.resolved;

  /// 대기 중인 상태인지 확인
  bool get isPending => this == CallRequestStatus.pending;
}
