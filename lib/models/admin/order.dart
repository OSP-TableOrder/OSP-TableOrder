import 'package:cloud_firestore/cloud_firestore.dart';

/// Order 모델 - 정규화된 주문 일괄 (Normalized)
///
/// Firestore의 Orders 컬렉션에 저장됨.
///
/// 역할:
/// - Receipt(영수증)은 여러 Order를 참조
/// - Order는 한 번의 주문 행위 또는 주문 일괄을 나타냄
/// - items 배열의 각 항목은 menuId를 통해 Menus 컬렉션 참조
///
/// 데이터 구조:
/// ```
/// Orders/{orderId}
/// ├─ receiptId: String        (Receipts/{receiptId} 참조)
/// ├─ storeId: String
/// ├─ tableId: String
/// ├─ items: [
/// │   {
/// │     menuId: String        (Menus/{menuId} 참조)
/// │     quantity: int
/// │     status: String        ('ordered', 'cooking', 'completed', 'canceled')
/// │     completedCount: int
/// │     orderedAt: Timestamp
/// │     priceAtOrder: int    (주문 시점의 메뉴 가격 - 히스토리 보존)
/// │   }
/// │ ]
/// ├─ totalPrice: int
/// ├─ createdAt: Timestamp
/// └─ updatedAt: Timestamp
/// ```
///
/// 주의: 메뉴 정보는 프로퍼티로 저장하지 않고, menuId로만 참조.
/// 메뉴 상세 정보는 MenuRepository.getMenusByIds()로 별도 조회.
class Order {
  /// Order ID (document ID)
  /// Firestore Orders 컬렉션의 document ID
  final String id;

  /// 영수증 ID (receiptId)
  /// Receipts/{receiptId} 참조
  /// 하나의 Receipt은 여러 Order를 포함할 수 있음
  final String receiptId;

  /// 가게 ID
  final String storeId;

  /// 테이블 ID
  final String tableId;

  /// 주문 항목 목록
  /// 각 OrderItem은 menuId를 통해 Menus 컬렉션 참조
  final List<OrderItem> items;

  /// 총 금액
  /// canceled 항목의 가격은 자동으로 제외되지 않음
  /// (계산 시 items를 순회하며 상태 확인 필요)
  final int totalPrice;

  /// Order 생성 시간
  final DateTime? createdAt;

  /// Order 마지막 수정 시간
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.receiptId,
    required this.storeId,
    required this.tableId,
    required this.items,
    required this.totalPrice,
    this.createdAt,
    this.updatedAt,
  });

  Order copyWith({
    String? receiptId,
    String? storeId,
    String? tableId,
    List<OrderItem>? items,
    int? totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id,
      receiptId: receiptId ?? this.receiptId,
      storeId: storeId ?? this.storeId,
      tableId: tableId ?? this.tableId,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Firestore 문서에서 Order로 변환
  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items = itemsList
        .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return Order(
      id: json['id'] ?? '',
      receiptId: json['receiptId'] ?? '',
      storeId: json['storeId'] ?? '',
      tableId: json['tableId'] ?? '',
      items: items,
      totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  /// Order를 Firestore 저장 형식으로 변환
  Map<String, dynamic> toJson() {
    return {
      'receiptId': receiptId,
      'storeId': storeId,
      'tableId': tableId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalPrice': totalPrice,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Firestore의 Timestamp 또는 String을 DateTime으로 파싱
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}

/// Order의 주문 항목 (OrderItem)
///
/// Orders.items 배열의 각 원소.
/// 메뉴는 menuId로 참조하며, 주문 시점의 가격은 priceAtOrder로 기록.
class OrderItem {
  /// 메뉴 ID
  /// Menus/{menuId} 참조
  /// 실제 메뉴 정보는 MenuRepository.getMenuById(menuId)로 조회
  final String menuId;

  /// 주문 수량
  final int quantity;

  /// 주문 상태
  /// - 'ordered': 방금 주문됨, 아직 조리 시작 안 함
  /// - 'cooking': 조리 중
  /// - 'completed': 조리 완료
  /// - 'canceled': 취소됨
  final String status;

  /// 완료된 수량 (completedCount)
  /// 부분 완료 시나리오 지원 (예: 10개 주문 중 5개만 먼저 완료)
  final int completedCount;

  /// 이 항목이 주문된 시간
  final DateTime? orderedAt;

  /// 주문 시점의 메뉴 가격
  /// 메뉴 가격이 변경되어도 과거 주문의 가격은 보존됨
  /// (히스토리 목적 + 결제 금액 일관성)
  final int priceAtOrder;

  const OrderItem({
    required this.menuId,
    required this.quantity,
    required this.status,
    required this.completedCount,
    this.orderedAt,
    required this.priceAtOrder,
  });

  OrderItem copyWith({
    String? menuId,
    int? quantity,
    String? status,
    int? completedCount,
    DateTime? orderedAt,
    int? priceAtOrder,
  }) {
    return OrderItem(
      menuId: menuId ?? this.menuId,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      completedCount: completedCount ?? this.completedCount,
      orderedAt: orderedAt ?? this.orderedAt,
      priceAtOrder: priceAtOrder ?? this.priceAtOrder,
    );
  }

  /// JSON에서 OrderItem으로 변환
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuId: json['menuId'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      status: json['status'] ?? 'ordered',
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      orderedAt: _parseDateTime(json['orderedAt']),
      priceAtOrder: (json['priceAtOrder'] as num?)?.toInt() ?? 0,
    );
  }

  /// Firestore의 Timestamp 또는 String을 DateTime으로 파싱
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// OrderItem을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'menuId': menuId,
      'quantity': quantity,
      'status': status,
      'completedCount': completedCount,
      'orderedAt': orderedAt?.toIso8601String(),
      'priceAtOrder': priceAtOrder,
    };
  }
}
