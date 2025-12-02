import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/models/common/order_menu_status.dart';

/// OrderMenu 모델 - "한 번의 주문 행위"를 나타냄
///
/// Order(영수증)의 menus 배열에 저장되며,
/// 고객이 "주문하기" 버튼을 누를 때마다 하나씩 추가됨.
///
/// 예시:
/// - 첫 주문: 음료 2개 → OrderMenu 1개 추가 (id: auto-gen-1)
/// - 두 번째 주문: 음식 1개 → OrderMenu 1개 추가 (id: auto-gen-2)
/// - 취소: 음료 취소 → 첫 번째 OrderMenu의 status를 canceled로 변경
class OrderMenu {
  /// OrderMenu 고유 ID (Firestore 자동 생성 ID)
  final String id;

  /// 주문 항목의 상태
  /// - ordered: 주문됨 (아직 조리 전)
  /// - cooking: 조리 중
  /// - completed: 완료 (제공됨)
  /// - canceled: 취소됨 (가격 계산에서 제외)
  final OrderMenuStatus status;

  /// 주문한 수량
  /// 예: 음료 2개 = quantity: 2
  final int quantity;

  /// 완료된 수량 (부분 제공 지원)
  /// 예: 5개 주문하고 3개만 먼저 제공 = completedCount: 3
  final int completedCount;

  /// 메뉴 정보
  /// 메뉴의 가격, 이름, 이미지 등이 포함됨
  final Menu menu;

  /// 주문 시간
  /// 이 주문 항목이 추가된 시간 (admin 페이지에서 주문 타임라인 표시용)
  final DateTime? orderedAt;

  const OrderMenu({
    required this.id,
    required this.status,
    required this.quantity,
    this.completedCount = 0,
    required this.menu,
    this.orderedAt,
  });

  bool get isCancelable => status.isCancelable;

  OrderMenu copyWith({
    OrderMenuStatus? status,
    int? quantity,
    int? completedCount,
    Menu? menu,
    DateTime? orderedAt,
  }) {
    return OrderMenu(
      id: id,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      completedCount: completedCount ?? this.completedCount,
      menu: menu ?? this.menu,
      orderedAt: orderedAt ?? this.orderedAt,
    );
  }
}
