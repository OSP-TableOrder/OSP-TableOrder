/// CallStaffLog 모델 - 직원 호출 요청 기록
///
/// 고객이 "직원 호출" 버튼을 누를 때 생성되며,
/// 해당 테이블의 영수증(Order/Receipt)과 연결됨.
class CallStaffLog {
  /// 호출 요청 ID
  final String id;

  /// 가게 ID
  final String storeId;

  /// 테이블 ID
  final String tableId;

  /// 테이블 이름
  final String table;

  /// 호출 메시지
  /// 예: "안녕하세요. 서빙 부탁드립니다."
  final String message;

  /// 호출 시간 (HHmm 형식)
  final String time;

  /// 해결 여부
  /// true: 직원이 확인함
  /// false: 아직 미확인
  final bool resolved;

  /// 영수증 ID (receiptId)
  /// Order(영수증)을 참조하여 특정 테이블의 특정 주문과 연결
  /// 형식: YYYYMMDDHHmmssSSS (예: 20241202143045123)
  final String? receiptId;

  /// 생성 시간 (Timestamp)
  final DateTime? createdAt;

  CallStaffLog({
    required this.id,
    required this.storeId,
    required this.tableId,
    required this.table,
    required this.message,
    required this.time,
    this.resolved = false,
    this.receiptId,
    this.createdAt,
  });
}
