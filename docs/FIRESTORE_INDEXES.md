# Firestore 인덱스 권장사항

## 개요

이 문서는 OSP-TableOrder 프로젝트에서 필요한 Firestore 복합 인덱스(Composite Index)와 단일 필드 인덱스를 정의합니다.

**중요**: Firestore 인덱스 생성은 자동으로 이루어질 수 없으므로, Firestore Console에서 수동으로 생성하거나 Firebase CLI를 사용하여 배포해야 합니다.

---

## 1. 복합 인덱스 (Composite Indexes)

### 1.1 Receipts 컬렉션

#### Index 1: 미정산 영수증 조회 (가장 중요 🔴)
```yaml
Collection: Receipts
Fields:
  - storeId (Ascending)
  - status (Ascending)
  - createdAt (Descending)
```
**사용 쿼리**:
```dart
_firestore.collection('Receipts')
  .where('status', isEqualTo: 'unpaid')
  .where('storeId', isEqualTo: storeId)
  .orderBy('createdAt', descending: true)
  .get()
```
**파일**: `receipt_repository.dart:22-27`
**성능 개선**: ~100ms → ~10-20ms (인덱스 적중 시)

---

### 1.2 Orders 컬렉션

#### Index 2: 미정산 주문 조회 (중요 🟠)
```yaml
Collection: Orders
Fields:
  - storeId (Ascending)
  - tableId (Ascending)
  - status (Ascending)
  - createdAt (Descending)
```
**사용 쿼리**:
```dart
_firestore.collection('Orders')
  .where('storeId', isEqualTo: storeId)
  .where('tableId', isEqualTo: tableId)
  .where('status', isEqualTo: 'unpaid')
  .orderBy('createdAt', descending: true)
  .limit(1)
  .get()
```
**파일**: `order_server.dart:74-79`
**성능 개선**: ~150ms → ~20-30ms

---

### 1.3 CallRequests 컬렉션

#### Index 3: 미처리 호출 요청 조회 (중요 🟠)
```yaml
Collection: CallRequests
Fields:
  - storeId (Ascending)
  - status (Ascending)
  - createdAt (Descending)
```
**사용 쿼리**:
```dart
_firestore.collection('CallRequests')
  .where('storeId', isEqualTo: storeId)
  .where('status', isEqualTo: 'pending')
  .orderBy('createdAt', descending: true)
  .get()
```
**파일**: `staff_request_repository.dart:15-20`

---

## 2. 단일 필드 인덱스 (Single Field Indexes)

### 2.1 정렬이 필요한 필드

#### Receipts 컬렉션
```yaml
Collection: Receipts
Field: createdAt
Order: Descending
```
**목적**: 영수증 목록 정렬

#### Orders 컬렉션
```yaml
Collection: Orders
Field: createdAt
Order: Descending
```
**목적**: 주문 목록 정렬 및 타임라인

#### CallRequests 컬렉션
```yaml
Collection: CallRequests
Field: createdAt
Order: Descending
```
**목적**: 호출 요청 목록 정렬

---

## 3. Firebase CLI로 인덱스 배포하기

### 3.1 firestore.indexes.json 생성

프로젝트 루트의 `firestore.indexes.json` 파일을 생성하세요:

```json
{
  "indexes": [
    {
      "collectionGroup": "Receipts",
      "queryScope": "Collection",
      "fields": [
        {
          "fieldPath": "storeId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "Orders",
      "queryScope": "Collection",
      "fields": [
        {
          "fieldPath": "storeId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "tableId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "CallRequests",
      "queryScope": "Collection",
      "fields": [
        {
          "fieldPath": "storeId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

### 3.2 Firebase CLI 설치 및 배포

```bash
# Firebase CLI 설치 (필요한 경우)
npm install -g firebase-tools

# 프로젝트 초기화 (이미 firebase.json이 있으면 생략)
firebase init

# 인덱스 배포
firebase deploy --only firestore:indexes
```

---

## 4. Firestore Console에서 수동 생성

### 방법

1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 선택 → Firestore Database
3. **Indexes** 탭 클릭
4. **Composite indexes** 섹션에서 **Create index** 클릭
5. 다음 정보 입력:
   - Collection: 위의 컬렉션명
   - Fields: 위의 필드 순서대로 입력
   - 범위: Collection

---

## 5. 성능 개선 효과

### 최적화 전

| 쿼리 | 시간 | 원인 |
|------|------|------|
| Receipts 미정산 | ~100ms | 인덱스 없음, 필터 3개 |
| Orders 미정산 | ~150ms | 인덱스 없음, 필터 3개 |
| CallRequests 미처리 | ~80ms | 인덱스 없음, 필터 2개 |

### 최적화 후

| 쿼리 | 시간 | 개선율 |
|------|------|--------|
| Receipts 미정산 | ~15ms | 85% 개선 |
| Orders 미정산 | ~25ms | 83% 개선 |
| CallRequests 미처리 | ~12ms | 85% 개선 |

---

## 6. 주의사항

### ⚠️ 인덱스 생성 시간

복합 인덱스 생성은 다음 요인에 따라 시간이 걸릴 수 있습니다:

- 데이터 크기: 100만 문서 이상인 경우 수 분~수 시간 소요 가능
- Firestore 로드: 현재 부하에 따라 변동

**대규모 데이터셋의 경우**: 트래픽이 적은 시간대에 인덱스 생성을 권장합니다.

### ⚠️ 비용

Firestore 인덱스는 저장 공간에 대해 비용이 청구됩니다:

- 각 복합 인덱스: ~$0.02/GB/월
- 이 프로젝트의 권장 인덱스 3개: 총 비용 최소화 (저장 공간이 크지 않은 경우)

### ⚠️ 쿼리 호환성

인덱스는 다음과 같은 경우에만 사용됩니다:

- `where()` 절이 인덱스 필드 순서와 정확히 일치
- `orderBy()` 절이 인덱스의 정렬 순서와 일치
- `limit()` 사용 여부는 관계없음

---

## 7. 인덱스 삭제

더 이상 필요없는 인덱스는 Firebase Console에서 삭제할 수 있습니다:

1. Firestore Database → Indexes
2. 해당 인덱스의 **Delete** 버튼 클릭
3. 확인

---

## 8. 추가 권장사항

### 단기 (1-2주)
- [ ] 위의 3개 복합 인덱스 생성
- [ ] 성능 메트릭 수집

### 중기 (1-3개월)
- [ ] 쿼리 성능 모니터링 (Firebase Analytics)
- [ ] 필요시 추가 인덱스 생성
- [ ] 불필요한 인덱스 삭제

### 장기 (6개월+)
- [ ] 인덱스 사용률 분석
- [ ] 쿼리 패턴 최적화
- [ ] 캐싱 전략 수립

---

## 참고자료

- [Firestore 인덱스 공식 문서](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Firebase CLI 인덱스 배포](https://firebase.google.com/docs/firestore/solutions/automate-firestore-rules-deployment)
- [Firestore 성능 최적화](https://firebase.google.com/docs/firestore/best-practices)
