import 'package:table_order/models/customer/order_menu.dart';
import 'package:table_order/models/customer/order_status.dart';

/// Order 모델 - 테이블의 "영수증(Receipt)" 역할
///
/// Firestore의 Receipts 컬렉션에 저장됨.
///
/// 아키텍처:
/// - Order = 한 테이블의 영수증/세션
/// - 테이블당 최대 하나의 unpaid Order 존재
/// - menus 배열의 각 OrderMenu = 고객이 "주문하기"를 누를 때마다 추가되는 주문 항목
///
/// 예시 시나리오:
/// ```
/// 16:00 - 고객이 "음료 2개" 주문 → OrderMenu 추가 (status: ordered)
/// 16:05 - 고객이 "음식 1개" 주문 → OrderMenu 추가 (menus 배열 확대)
/// 16:10 - 고객이 음료 취소 → 첫 번째 OrderMenu status를 canceled로 변경
/// 16:30 - 결제 완료 → status를 paid로 변경 → 새로운 Order 생성 대기
/// ```
///
/// totalPrice는 canceled 상태의 OrderMenu를 자동으로 제외하고 계산됨.
class Order {
  /// 영수증 ID (receiptId)
  /// 형식: YYYYMMDDHHmmssSSS (예: 20241202143045123)
  /// Firestore Orders 컬렉션의 document ID로 사용됨
  final String id;

  /// 가게 ID
  final String storeId;

  /// 테이블 ID
  final String tableId;

  /// 총 금액 (canceled 항목 자동 제외)
  final int totalPrice;

  /// 주문 항목 목록
  /// 각 OrderMenu는 "한 번의 주문 행위"를 나타냄
  /// - 고객이 주문할 때마다 OrderMenu 추가
  /// - 메뉴 취소 시 해당 OrderMenu 상태를 canceled로 변경
  final List<OrderMenu> menus;

  /// 정산 상태 (영수증 상태)
  /// - unpaid: 진행 중인 주문 (고객이 결제하지 않음)
  /// - paid: 정산 완료 (고객이 결제함)
  final OrderStatus status;

  /// 영수증 생성 시간
  /// Admin 페이지에서 주문 시간 표시에 사용됨
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.storeId,
    required this.tableId,
    required this.totalPrice,
    required this.menus,
    this.status = OrderStatus.unpaid,
    this.createdAt,
  });

  Order copyWith({int? totalPrice, List<OrderMenu>? menus, OrderStatus? status, DateTime? createdAt}) {
    return Order(
      id: id,
      storeId: storeId,
      tableId: tableId,
      totalPrice: totalPrice ?? this.totalPrice,
      menus: menus ?? this.menus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
