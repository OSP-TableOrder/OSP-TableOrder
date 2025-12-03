# Firestore 데이터 정제 가이드

## 개요

이 가이드는 Firestore의 혼재된 데이터 타입과 불일치를 정제하는 방법을 설명합니다.

---

## 1. 타입 불일치 정제

### 1.1 storeId 타입 정규화

**문제**: storeId가 int 또는 string으로 혼재되어 있음

#### 자동 정제 스크립트

```dart
// lib/server/admin_server/firestore_cleanup.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_order/server/admin_server/data_type_normalizer.dart';

class FirestoreCleanup {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// storeId를 모두 String으로 정규화
  Future<void> normalizeStoreIds() async {
    try {
      // 영향받는 컬렉션들
      final collections = ['Receipts', 'Orders', 'Tables', 'Menus', 'Categories'];

      for (final collectionName in collections) {
        print('정제 중: $collectionName...');

        final snapshot = await _firestore.collection(collectionName).get();
        final batch = _firestore.batch();
        int updated = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final storeId = data['storeId'];

          // storeId가 int인 경우만 정규화
          if (storeId != null && storeId is int) {
            batch.update(doc.reference, {
              'storeId': storeId.toString(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            updated++;

            // 배치 크기 제한 (500)
            if (updated % 500 == 0) {
              await batch.commit();
              print('  커밋: $updated 문서 업데이트됨');
            }
          }
        }

        // 남은 문서 커밋
        if (updated % 500 != 0) {
          await batch.commit();
        }

        print('  완료: $updated 문서 정규화됨\n');
      }
    } catch (e) {
      print('정제 중 오류: $e');
      rethrow;
    }
  }

  /// price를 모두 int로 정규화
  Future<void> normalizePrices() async {
    try {
      print('정제 중: Menus/Orders의 price...');

      final menuSnapshot = await _firestore.collection('Menus').get();
      final batch = _firestore.batch();
      int updated = 0;

      for (final doc in menuSnapshot.docs) {
        final data = doc.data();
        final price = data['price'];

        // price가 string인 경우만 정규화
        if (price != null && price is String) {
          final intPrice = int.tryParse(price) ?? 0;
          batch.update(doc.reference, {
            'price': intPrice,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          updated++;

          if (updated % 500 == 0) {
            await batch.commit();
            print('  커밋: $updated 문서 업데이트됨');
          }
        }
      }

      if (updated % 500 != 0) {
        await batch.commit();
      }

      print('  완료: $updated 문서 정규화됨\n');
    } catch (e) {
      print('정제 중 오류: $e');
      rethrow;
    }
  }
}
```

#### 실행 방법

```dart
// 어디든지 한 번 실행
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final cleanup = FirestoreCleanup();
  await cleanup.normalizeStoreIds();
  await cleanup.normalizePrices();

  print('정제 완료!');
}
```

---

### 1.2 필드명 표준화

**문제**: 동일한 의미의 필드가 다른 이름으로 저장됨

| 컬렉션 | 문제 | 해결책 |
|--------|------|-------|
| Menus | categoryId vs category | categoryId만 사용 |
| Orders | menu.categoryId vs categoryName | categoryId만 사용 |
| CallRequests | tableName의 null | 기본값: tableId 사용 |

#### Firestore Console 쿼리로 확인

```javascript
// 콘솔에서 실행 (JavaScript)

// categoryId가 없는 Menus 찾기
db.collection("Menus")
  .where("categoryId", "==", null)
  .get()
  .then(querySnapshot => {
    console.log(querySnapshot.size + "개의 메뉴에 categoryId가 없음");
  });

// 빈 tableName을 가진 CallRequests 찾기
db.collection("CallRequests")
  .where("tableName", "==", "")
  .get()
  .then(querySnapshot => {
    console.log(querySnapshot.size + "개의 호출이 tableName이 비어있음");
  });
```

---

## 2. Null/Empty 데이터 정제

### 2.1 문제 식별

```dart
// data_audit.dart - 문제 데이터 찾기
Future<void> auditNullFields() async {
  final collections = {
    'Receipts': ['storeId', 'tableId', 'status'],
    'Orders': ['storeId', 'menus', 'status'],
    'Menus': ['storeId', 'name', 'price', 'categoryId'],
    'CallRequests': ['storeId', 'tableId', 'tableName', 'message'],
  };

  for (final entry in collections.entries) {
    final collectionName = entry.key;
    final requiredFields = entry.value;

    print('\n=== $collectionName 감사 ===');

    final snapshot = await _firestore.collection(collectionName).get();
    final issues = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      for (final field in requiredFields) {
        final value = data[field];

        if (value == null) {
          issues['$field: null'] = (issues['$field: null'] ?? 0) + 1;
        } else if (value is String && value.isEmpty) {
          issues['$field: empty'] = (issues['$field: empty'] ?? 0) + 1;
        }
      }
    }

    if (issues.isEmpty) {
      print('✓ 문제 없음 (${ snapshot.size} 문서)');
    } else {
      print('✗ 발견된 문제:');
      for (final entry in issues.entries) {
        print('  - ${entry.key}: ${entry.value}건');
      }
    }
  }
}
```

### 2.2 자동 정제

```dart
Future<void> cleanupEmptyFields() async {
  print('빈 필드 정제 중...\n');

  // 1. CallRequests의 빈 tableName 정제
  print('1. CallRequests의 빈 tableName 정제...');
  final callSnapshot = await _firestore
      .collection('CallRequests')
      .where('tableName', isEqualTo: '')
      .get();

  var batch = _firestore.batch();
  for (final doc in callSnapshot.docs) {
    final data = doc.data();
    final tableId = data['tableId'] ?? 'unknown';

    batch.update(doc.reference, {
      'tableName': '테이블($tableId)',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  if (callSnapshot.docs.isNotEmpty) {
    await batch.commit();
    print('  ✓ ${callSnapshot.size}개 정제됨\n');
  }

  // 2. 기본 필드 누락된 문서 확인 및 로깅
  print('2. 필드 누락 문서 확인...');
  final ordersSnapshot = await _firestore.collection('Orders').get();

  int missingCount = 0;
  for (final doc in ordersSnapshot.docs) {
    final data = doc.data();
    if (data['storeId'] == null || data['tableId'] == null) {
      print('  경고: Orders/${doc.id}에 필수 필드가 누락됨');
      missingCount++;
    }
  }

  if (missingCount == 0) {
    print('  ✓ 누락된 필드 없음\n');
  } else {
    print('  ✗ $missingCount개 문서에 필드 누락됨\n');
  }
}
```

---

## 3. 마이그레이션 데이터 검증

### 3.1 CallRequests의 receiptId 검증

```dart
/// CallRequests의 receiptId 유효성 검사
Future<void> validateReceiptIds() async {
  print('CallRequests의 receiptId 검증 중...\n');

  final callSnapshot = await _firestore
      .collection('CallRequests')
      .get();

  int validCount = 0;
  int missingCount = 0;
  int invalidCount = 0;

  for (final doc in callSnapshot.docs) {
    final receiptId = doc.data()['receiptId'] as String?;

    if (receiptId == null || receiptId.isEmpty) {
      print('경고: CallRequests/${doc.id}의 receiptId가 없음');
      missingCount++;
      continue;
    }

    // Receipts 컬렉션에서 해당 receiptId 존재 확인
    final receiptExists =
        (await _firestore.collection('Receipts').doc(receiptId).get()).exists;

    if (receiptExists) {
      validCount++;
    } else {
      print('오류: CallRequests/${doc.id}의 receiptId($receiptId)가 유효하지 않음');
      invalidCount++;
    }
  }

  print('\n=== 검증 결과 ===');
  print('유효한 receiptId: $validCount');
  print('누락된 receiptId: $missingCount');
  print('유효하지 않은 receiptId: $invalidCount');

  if (missingCount > 0 || invalidCount > 0) {
    print('\n⚠️ 수동 매핑 필요!');
  }
}
```

### 3.2 Orders의 receiptId 검증

```dart
/// Orders의 receiptId가 실제 Receipt과 연결되어 있는지 검증
Future<void> validateOrderReceiptLinks() async {
  print('Orders의 receiptId 링크 검증 중...\n');

  final ordersSnapshot = await _firestore.collection('Orders').get();

  int validLinks = 0;
  int brokenLinks = 0;

  for (final doc in ordersSnapshot.docs) {
    final receiptId = doc.data()['receiptId'] as String?;

    if (receiptId == null) {
      // receiptId가 없는 Orders는 orphaned 상태
      print('경고: Orders/${doc.id}의 receiptId가 없음 (orphaned)');
      brokenLinks++;
      continue;
    }

    final receiptExists =
        (await _firestore.collection('Receipts').doc(receiptId).get()).exists;

    if (receiptExists) {
      validLinks++;
    } else {
      print('오류: Orders/${doc.id}의 receiptId($receiptId)가 존재하지 않음');
      brokenLinks++;
    }
  }

  print('\n=== 검증 결과 ===');
  print('유효한 링크: $validLinks');
  print('깨진 링크: $brokenLinks');
}
```

---

## 4. 정제 실행 계획

### 단계 1: 감사 (1일)
```dart
await auditNullFields();
await validateReceiptIds();
await validateOrderReceiptLinks();
```

### 단계 2: 백업 (필수)
- Firebase Console에서 **Backups** 메뉴로 이동
- **Create Manual Backup** 클릭
- 전체 데이터베이스 백업

### 단계 3: 정제 (위험도별 실행)
```dart
// 낮은 위험도 - 바로 실행 가능
await normalizeStoreIds();
await normalizePrices();

// 중간 위험도 - 검증 후 실행
await cleanupEmptyFields();

// 높은 위험도 - 문제 분석 후 수동 실행
// await fixOrphanedOrders();
```

### 단계 4: 검증
```dart
await auditNullFields(); // 재확인
await validateReceiptIds();
await validateOrderReceiptLinks();
```

---

## 5. 안전 체크리스트

- [ ] Firestore 자동 백업 활성화
- [ ] 수동 백업 생성
- [ ] 정제 스크립트 로컬에서 테스트
- [ ] 테스트 데이터로 먼저 실행
- [ ] 프로덕션 실행 전 재검증
- [ ] 정제 전후 메트릭 기록
- [ ] 롤백 계획 수립 (백업 복원)

---

## 6. 문제 해결

### 실패한 정제 작업 복구

```bash
# Firebase CLI로 백업에서 복구
firebase firestore:restore BACKUP_ID
```

### 부분 정제 다시 실행

```dart
// 조건부 실행으로 정제 재개
Future<void> resumeCleanup() async {
  final ordersSnapshot = await _firestore
      .collection('Orders')
      .where('storeId', isEqualTo: null) // 아직 처리 안 된 것만
      .get();

  // 정제 로직 실행
}
```

---

## 참고자료

- [Firestore 백업](https://firebase.google.com/docs/firestore/solutions/automate-firestore-backup)
- [배치 쓰기](https://firebase.google.com/docs/firestore/manage-data/transactions#batched-writes)
- [데이터 검증 best practices](https://firebase.google.com/docs/firestore/best-practices)
