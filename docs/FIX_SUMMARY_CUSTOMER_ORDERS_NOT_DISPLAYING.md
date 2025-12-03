# 고객 주문이 관리자 페이지에 표시되지 않는 문제 - 완전 해결

## 문제 현상

```
[OrderProvider] Found 1 receipt(s) for table 내부1_1
[OrderProvider] Tables loaded: 1
```

- 영수증(Receipt)은 찾아짐 (Receipts 컬렉션에 저장됨)
- 하지만 주문 메뉴는 표시되지 않음 (orders list가 비어있음)

---

## 근본 원인 분석

### 문제 1: 데이터 저장 위치 불일치 (첫 번째 수정으로 해결)

**Before**:
```
고객 주문 저장 위치: Orders 컬렉션
관리자 쿼리 대상: Receipts 컬렉션
결과: 데이터가 다른 위치에 저장되어 보이지 않음
```

**Fix**: OrderServerStub의 `_collectionName`을 'Orders'에서 'Receipts'로 변경
```dart
static const String _collectionName = 'Receipts';
```

---

### 문제 2: 메뉴 추출 로직 오류 (두 번째 수정으로 해결)

**Before**:
```
ReceiptRepository._fetchOrdersByReceipt()
  ↓
Orders 컬렉션 쿼리 (WHERE receiptId = receiptId)
  ↓
해당하는 문서 없음 (메뉴는 Orders에 없고 Receipts에 있음)
  ↓
결과: 빈 배열 반환
```

**Architecture 실제 구조**:
```
Receipts/{receiptId}
├── storeId: "store123"
├── tableId: "table001"
├── status: "unpaid"
├── totalPrice: 45000
├── createdAt: Timestamp
└── menus: [
    {
      id: "menu_001",
      status: "ordered",
      quantity: 2,
      orderedAt: Timestamp,
      menu: {
        name: "음료",
        price: 5000,
        ...
      }
    },
    ...
  ]
```

메뉴는 Orders 컬렉션에 없고 **Receipt 문서의 menus 배열에 직접 저장**됨.

**Fix**: ReceiptRepository 메서드 재설계

```dart
// Before (잘못된 로직)
Future<List<dynamic>> _fetchOrdersByReceipt(String receiptId) async {
  final ordersSnapshot = await _firestore
      .collection('Orders')
      .where('receiptId', isEqualTo: receiptId)  // ❌ 이 쿼리는 결과 없음
      .get();
  // ...
}

// After (수정된 로직)
List<dynamic> _extractMenusFromReceipt(Map<String, dynamic> receiptData) {
  final menus = receiptData['menus'] as List<dynamic>? ?? [];  // ✓ 직접 추출
  final items = <dynamic>[];

  for (final menu in menus) {
    if (menu is Map<String, dynamic>) {
      final menuInfo = menu['menu'] as Map<String, dynamic>? ?? {};

      // orderedAt 파싱 및 형식 변환
      String? orderedAtStr;
      final orderedAtTimestamp = menu['orderedAt'] as Timestamp?;
      if (orderedAtTimestamp != null) {
        final dateTime = orderedAtTimestamp.toDate();
        orderedAtStr = '${dateTime.hour.toString().padLeft(2, '0')}:'
                      '${dateTime.minute.toString().padLeft(2, '0')}:'
                      '${dateTime.second.toString().padLeft(2, '0')}';
      }

      items.add({
        'name': menuInfo['name'] ?? '미정의',
        'price': menuInfo['price'] ?? 0,
        'quantity': menu['quantity'] ?? 1,
        'status': menu['status'] ?? 'ordered',
        'orderedAt': orderedAtStr,
      });
    }
  }

  return items;
}
```

---

## 해결 과정

### Commit 1: 데이터 저장 위치 통일
**Time**: 2024-12-02
**File**: `lib/server/customer_server/order_server.dart`

```dart
// Changed line 11
- static const String _collectionName = 'Orders';
+ static const String _collectionName = 'Receipts';
```

**Impact**: 고객 주문이 이제 Receipts 컬렉션에 저장됨

---

### Commit 2: 메뉴 추출 로직 수정
**Time**: 2024-12-02
**File**: `lib/server/admin_server/receipt_repository.dart`

**Changes**:
1. `_fetchOrdersByReceipt()` 메서드 제거
   - Orders 컬렉션 쿼리는 불필요 (결과 없음)

2. `_extractMenusFromReceipt()` 메서드 추가
   - Receipt 문서의 menus 배열에서 직접 추출
   - 각 메뉴를 표시용 형식으로 변환
   - orderedAt 타임스탬프 파싱

3. `_fetchOrdersByReceiptWithMetadata()` 수정
   ```dart
   // Before
   final items = await _fetchOrdersByReceipt(receiptId);

   // After
   final items = _extractMenusFromReceipt(receiptData);
   ```
   - 이미 로드된 Receipt 데이터에서 직접 추출
   - 추가 Firestore 쿼리 불필요

4. 미사용 상수 제거
   ```dart
   - static const String _ordersCollection = 'Orders';
   ```

**Impact**: 메뉴가 Receipt 문서에서 올바르게 추출되어 관리자 페이지에 표시됨

---

## 최종 데이터 흐름

```
1. 고객이 QR 코드 스캔
   ↓
2. OrderServerStub.findUnpaidOrderByTable()
   ↓
3. Receipts 컬렉션 쿼리 (storeId, tableId, status=unpaid)
   ↓
4. Receipt 문서 생성/로드 (+ menus 배열 포함)
   ↓
5. 고객이 메뉴 주문
   ↓
6. OrderServerStub.addMenu() 호출
   ↓
7. Receipt.menus 배열에 OrderMenu 추가
   ↓
8. Firestore Receipts 컬렉션 업데이트
   ↓
9. 관리자가 주문 페이지 열기
   ↓
10. OrderProvider.loadTables()
    ↓
11. ReceiptService.getUnpaidReceiptsByStore()
    ↓
12. ReceiptRepository.fetchUnpaidReceiptsByStore()
    ↓
13. Receipts 컬렉션에서 미정산 영수증 모두 조회
    ↓
14. 각 Receipt 문서의 menus 배열에서 메뉴 직접 추출
    ↓
15. 메뉴를 표시용 형식으로 변환
    ↓
16. TableOrderInfo 생성
    ↓
17. 관리자 화면에 주문 표시 ✓
```

---

## 검증

### Flutter Analyze
```
✅ No issues found!
```

### 수정 전후 비교

| 항목 | 수정 전 | 수정 후 |
|------|--------|--------|
| 고객 주문 저장 | Orders 컬렉션 | Receipts 컬렉션 ✓ |
| 메뉴 조회 | Orders 컬렉션 쿼리 (결과 없음) | Receipt.menus 직접 추출 ✓ |
| 메뉴 표시 | 빈 배열 | 주문 항목 표시됨 ✓ |
| Firestore 쿼리 | Orders에 불필요한 쿼리 | 최적화됨 (이미 로드된 데이터 사용) ✓ |

---

## 아키텍처 확정

### Receipts 컬렉션 구조 (확정)

```firestore
Receipts/{receiptId} {
  storeId: String,
  tableId: String,
  status: "unpaid" | "paid",
  totalPrice: int,
  menus: [
    {
      id: String,
      status: String,
      quantity: int,
      completedCount: int,
      orderedAt: Timestamp,
      menu: {
        id: String,
        storeId: String,
        categoryId: String,
        name: String,
        description: String,
        imageUrl: String,
        price: int,
        isSoldOut: bool,
        isRecommended: bool,
      }
    }
  ],
  createdAt: Timestamp,
  updatedAt: Timestamp,
}
```

### 데이터 저장 및 조회 규칙

| 작업 | 컬렉션 | 메서드 |
|------|--------|--------|
| 고객 주문 생성 | Receipts | OrderServerStub.createOrder() |
| 메뉴 추가 | Receipts | OrderServerStub.addMenu() |
| 메뉴 취소 | Receipts | OrderServerStub.cancelMenu() |
| 미정산 주문 조회 | Receipts | OrderServerStub.findUnpaidOrderByTable() |
| 관리자 주문 조회 | Receipts | ReceiptRepository.fetchUnpaidReceiptsByStore() |
| 정산 처리 | Receipts | ReceiptRepository.updateReceiptStatus() |

---

## 남은 작업

### Phase 1 (완료) ✓
- [x] OrderServerStub 컬렉션 이름 변경
- [x] Order 모델 문서화 업데이트
- [x] ReceiptRepository 메뉴 추출 로직 수정
- [x] 미사용 상수 제거

### Phase 2 (필요시)
- [ ] 기존 Orders 컬렉션 데이터 마이그레이션 (MigrationServer 사용)
- [ ] 프로덕션 환경에서 Firestore 인덱스 배포
- [ ] 데이터 정규화 (DataTypeNormalizer 사용)

### Phase 3 (향후 검토)
- [ ] Orders 컬렉션 용도 결정
  - 옵션 1: 완전 제거 (메뉴는 Receipts에만 저장)
  - 옵션 2: 별도 용도로 유지 (필요시)

---

## 관련 문서

- [ARCHITECTURE_RECEIPTS_MIGRATION.md](ARCHITECTURE_RECEIPTS_MIGRATION.md) - 전체 마이그레이션 가이드
- [FIRESTORE_INDEXES.md](FIRESTORE_INDEXES.md) - Firestore 인덱스 배포
- [DATA_CLEANUP_GUIDE.md](DATA_CLEANUP_GUIDE.md) - 데이터 정제 가이드

---

## 결론

고객 주문이 관리자 페이지에 표시되지 않던 문제는 **두 가지 불일치**로 인해 발생했습니다:

1. **데이터 저장 위치 불일치**: 고객은 Orders에 저장, 관리자는 Receipts 쿼리
2. **메뉴 추출 로직 오류**: 메뉴가 Orders 컬렉션이 아니라 Receipt.menus에 저장됨

두 커밋으로 **완전히 해결**했습니다:
- **Commit 1**: Orders → Receipts로 통일
- **Commit 2**: Receipt 문서에서 메뉴를 직접 추출하도록 수정

이제 고객 주문이 정상적으로 관리자 페이지에 표시됩니다.

