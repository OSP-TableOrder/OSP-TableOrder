# Receipts Collection 마이그레이션 가이드

## 개요

이 가이드는 OSP-TableOrder의 **중요한 아키텍처 변경**을 설명합니다: 고객 주문 저장 위치를 **Orders 컬렉션에서 Receipts 컬렉션으로 변경**.

---

## 문제 상황

### 🔴 발견된 문제

1. **고객이 주문을 했지만 관리자 페이지에 표시되지 않음**
2. **Firestore에서 Receipts 컬렉션이 생성되지 않음**
3. **Orders 컬렉션에서 여전히 영수증을 관리하는 상황**

### 근본 원인

- **Admin 측**: ReceiptRepository와 ReceiptService가 Receipts 컬렉션을 쿼리하도록 업데이트됨
- **Customer 측**: OrderServerStub가 여전히 Orders 컬렉션에 저장하고 있음
- **결과**: 데이터 불일치로 인해 고객 주문이 관리자 화면에 표시되지 않음

---

## 해결책

### 변경 사항 1: OrderServerStub 컬렉션 이름 변경

**파일**: `lib/server/customer_server/order_server.dart`

```dart
// Before
static const String _collectionName = 'Orders';

// After
static const String _collectionName = 'Receipts';
```

**영향받는 메서드**:
- `createOrder()` - Receipts 컬렉션에 새 영수증 생성
- `findById()` - Receipts 컬렉션에서 영수증 조회
- `findUnpaidOrderByTable()` - Receipts 컬렉션에서 미정산 영수증 조회 (자동으로 고정됨)
- `addMenu()` - 해당 영수증(Receipts 문서)에 메뉴 추가
- `cancelMenu()` - 해당 영수증(Receipts 문서)의 메뉴 취소

### 변경 사항 2: Order 모델 문서화 업데이트

**파일**: `lib/models/customer/order.dart`

```dart
// Before
/// Firestore의 Orders 컬렉션에 저장됨.

// After
/// Firestore의 Receipts 컬렉션에 저장됨.
```

---

## 아키텍처 설계

### 용어 정의

| 용어 | 의미 | Firestore 위치 |
|------|------|---------|
| **Receipt** | 테이블의 한 번의 정산 세션 (영수증) | Receipts 컬렉션 |
| **Order** | 고객이 "주문하기"를 클릭할 때마다 추가되는 개별 주문 항목 | Receipts.menus[] 배열 |
| **OrderMenu** | Receipt 내의 개별 메뉴 항목 | Receipts.menus[].menu 구조 |

### Firestore 구조

#### Receipts 컬렉션 (고객이 생성)

```firestore
Receipts/20241202143045123 {
  storeId: "store123",           // 가게 ID
  tableId: "table001",           // 테이블 ID
  status: "unpaid",              // "unpaid" 또는 "paid"
  totalPrice: 45000,             // 총 금액 (취소된 항목 제외)
  menus: [
    {
      id: "menu_001",
      status: "ordered",
      quantity: 2,
      completedCount: 0,
      orderedAt: Timestamp,
      menu: {
        id: "menu_id",
        name: "음료",
        price: 5000,
        // ... 기타 메뉴 정보
      }
    },
    // ... 추가 주문 항목
  ],
  createdAt: Timestamp,          // 영수증 생성 시간
  updatedAt: Timestamp,          // 마지막 수정 시간
}
```

### 데이터 흐름

```
고객 QR 코드 스캔
  ↓
OrderServerStub.findUnpaidOrderByTable()
  ↓
Receipts 컬렉션에서 (storeId, tableId, status=unpaid) 조회
  ↓
기존 영수증이 없으면 OrderServerStub.createOrder()
  ↓
새로운 Receipt 문서를 Receipts 컬렉션에 생성
  ↓
고객이 메뉴를 주문하면 OrderServerStub.addMenu()
  ↓
Receipt의 menus 배열에 OrderMenu 추가
  ↓
관리자는 ReceiptService.getUnpaidReceiptsByStore()로 조회
  ↓
관리자 화면에 주문 표시됨 ✓
```

---

## 마이그레이션 체크리스트

### Phase 1: 검증 (지금 상태)

- [x] OrderServerStub 컬렉션 이름을 'Receipts'로 변경
- [x] Order 모델 문서화 업데이트
- [x] Admin 측에서 ReceiptService가 Receipts 쿼리 중인지 확인
- [x] Flutter analyze - 에러 없음 확인

### Phase 2: 데이터 마이그레이션 (향후)

**기존 Orders 컬렉션 데이터를 Receipts로 마이그레이션하려면**:

```dart
// MigrationServer.dart 실행
final migration = MigrationServer();
await migration.executeMigration();
```

단계:
1. 기존 Orders 컬렉션의 모든 문서를 Receipts로 복사
2. CallRequests에 receiptId 필드 추가 (링크 설정)
3. Firestore 백업 생성 후 진행 권장

### Phase 3: Firestore 인덱스 배포 (필수)

**필요한 복합 인덱스**:

```yaml
Receipts:
  - storeId (Ascending)
  - status (Ascending)
  - createdAt (Descending)
```

배포 방법:
```bash
firebase deploy --only firestore:indexes
```

자세한 내용: `docs/FIRESTORE_INDEXES.md` 참고

---

## 테스트 방법

### 1. 고객 주문 흐름 테스트

```
1. 고객 앱에서 QR 코드 스캔
2. 가게/테이블 선택
3. 메뉴 추가 및 주문
4. Firestore Console에서 Receipts 컬렉션 확인
   → 새로운 Receipt 문서가 생성되어야 함
```

### 2. 관리자 주문 조회 테스트

```
1. 관리자 앱 실행
2. "주문" 탭에서 현재 주문 확인
3. 고객이 주문한 항목이 관리자 페이지에 표시되는지 확인
   → 표시되어야 함 ✓
```

### 3. 정산 프로세스 테스트

```
1. 관리자가 주문 완료 후 "정산" 클릭
2. ReceiptService.updateReceiptStatus() 호출됨
3. Receipts 컬렉션의 status가 "paid"로 변경됨
4. 주문이 목록에서 제거됨
```

---

## 주의사항

### ⚠️ 기존 데이터 처리

- **이미 생성된 Orders 컬렉션의 데이터**: `MigrationServer.executeMigration()` 실행 필요
- **백업 필수**: Firestore Console에서 수동 백업 생성 후 마이그레이션 진행
- **테스트 환경 먼저**: 프로덕션 배포 전 테스트 환경에서 마이그레이션 검증

### ⚠️ 코드 호환성

다음 코드들은 이제 Receipts 컬렉션을 쿼리합니다:
- `OrderServerStub` (고객 측)
- `ReceiptRepository` (관리자 측)
- `ReceiptService` (관리자 비즈니스 로직)

Order 모델의 의미는 변하지 않음 (여전히 "테이블의 영수증" 역할)

---

## 향후 개선 사항

### 단기 (1-2주)

- [ ] 기존 Orders 데이터 마이그레이션
- [ ] Firestore 인덱스 배포
- [ ] 프로덕션 환경에서 검증

### 중기 (1-3개월)

- [ ] Orders 컬렉션 용도 재정의 (필요시)
  - 옵션 1: 완전히 제거 (메뉴는 Receipts.menus 배열에만 저장)
  - 옵션 2: 유지 (OrderMenu 상태 변경 이력 추적용 별도 컬렉션)
- [ ] 데이터 정규화 (`DataTypeNormalizer` 사용)
- [ ] 성능 모니터링 및 최적화

### 장기 (6개월+)

- [ ] 통계 및 분석 컬렉션 추가
- [ ] 캐싱 전략 수립
- [ ] 아키텍처 문서화 완성

---

## 참고자료

- [ORDER 모델 문서](../lib/models/customer/order.dart)
- [ReceiptRepository 구현](../lib/server/admin_server/receipt_repository.dart)
- [ReceiptService 구현](../lib/service/admin/receipt_service.dart)
- [마이그레이션 서버](../lib/server/admin_server/migration_server.dart)
- [Firestore 인덱스 가이드](./FIRESTORE_INDEXES.md)
- [데이터 정제 가이드](./DATA_CLEANUP_GUIDE.md)

---

## 자주 묻는 질문

### Q: 왜 Orders 컬렉션이 아니라 Receipts 컬렉션을 사용하나요?

**A**: Order 모델의 의미상 "테이블의 영수증"을 나타내므로, Receipts 컬렉션이 의미론적으로 더 정확합니다. 또한 Admin 측에서 이미 Receipts 쿼리로 전환했으므로 일관성을 위해 Customer 측도 통일했습니다.

### Q: 기존 Orders 컬렉션의 데이터는 어떻게 되나요?

**A**: `MigrationServer.executeMigration()`을 실행하여 자동으로 Receipts로 복사됩니다. 프로덕션 배포 전에 테스트 환경에서 먼저 검증하세요.

### Q: OrderMenu와 Order의 차이가 뭔가요?

**A**:
- **Order** = 테이블의 한 번의 정산 세션 (Receipts 문서)
- **OrderMenu** = Order 내의 개별 메뉴 항목 (menus 배열의 원소)

고객이 "주문하기" 버튼을 클릭할 때마다 OrderMenu가 Order의 menus 배열에 추가됩니다.

### Q: Firestore 인덱스는 언제 생성해야 하나요?

**A**: 프로덕션 배포 후 가능한 빨리 생성하세요. 인덱스 없이도 작동하지만 성능이 저하됩니다. `FIRESTORE_INDEXES.md`의 배포 방법을 참고하세요.

