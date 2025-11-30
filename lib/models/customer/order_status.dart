enum OrderStatus {
  unpaid,  // 미정산 (진행 중)
  paid;    // 정산됨 (완료)

  bool get isUnpaid => this == OrderStatus.unpaid;
  bool get isPaid => this == OrderStatus.paid;
}
