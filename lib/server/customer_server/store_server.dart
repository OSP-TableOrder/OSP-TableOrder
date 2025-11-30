import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_order/models/customer/store.dart';

class StoreServer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static const String _collectionName = 'Stores';

  /// UID에 해당하는 Store 정보 조회
  Future<Store?> fetchStoreByUid(String uid) async {
    try {
      final CollectionReference usersRef = _firestore.collection('Users');
      final DocumentReference docRef = usersRef.doc(uid);

      return await docRef.get().then((DocumentSnapshot snapshot) {
        if (!snapshot.exists) return null;

        final storeId = snapshot.get('storeId') as String?;
        if (storeId == null) return null;

        return findById(storeId);
      });
    } catch (e) {
      developer.log('Error fetching store by uid: $e', name: 'StoreServer');
      return null;
    }
  }

  /// Store ID로 조회
  Future<Store?> findById(String id) async {
    try {
      final CollectionReference storesRef = _firestore.collection(
        _collectionName,
      );
      final DocumentReference docRef = storesRef.doc(id);

      return await docRef.get().then((DocumentSnapshot snapshot) {
        if (!snapshot.exists) return null;

        return _parseStore(snapshot.id, snapshot.data() as Map<String, dynamic>?);
      });
    } catch (e) {
      developer.log('Error fetching store: $e', name: 'StoreServer');
      return null;
    }
  }

  /// 모든 Store 조회
  Future<List<Store>> fetchStores() async {
    try {
      final CollectionReference collectionRef = _firestore.collection(
        _collectionName,
      );

      return await collectionRef.get().then((QuerySnapshot snapshot) {
        List<QueryDocumentSnapshot> list = snapshot.docs;
        List<Store> stores = [];

        for (var doc in list) {
          final store = _parseStore(
            doc.id,
            doc.data() as Map<String, dynamic>?,
          );
          if (store != null) {
            stores.add(store);
          }
        }

        return stores;
      });
    } catch (e) {
      developer.log('Error fetching stores: $e', name: 'StoreServer');
      return [];
    }
  }

  /// 사장에게 새로운 가게 정보 저장
  ///
  /// Firebase Auth에서 사장 계정을 생성하고,
  /// Firestore에 stores/{storeId}와 users/{uid} 데이터를 WriteBatch를 사용 생성
  Future<Map<String, dynamic>> createStoreWithOwner({
    required String storeName,
    required String ownerEmail,
    required String ownerPassword,
  }) async {
    try {
      // 1. Firebase Auth에서 사장 계정 생성
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: ownerEmail,
            password: ownerPassword,
          );

      final User? user = userCredential.user;
      if (user == null) {
        return {"success": false, "message": "계정 생성에 실패했습니다."};
      }

      // 2. Firestore 자동 생성 ID 획득
      final storeDocRef = _firestore.collection(_collectionName).doc();
      final String storeId = storeDocRef.id;

      // 3. WriteBatch를 stores와 users 컬렉션 생성 처리
      final WriteBatch batch = _firestore.batch();

      // stores/{storeId} 문서 생성
      batch.set(storeDocRef, {
        'name': storeName,
        'isOpened': true, // 기본값: 영업 중
        'notice': '', // 기본값: 빈 문자열
        'createdAt': FieldValue.serverTimestamp(),
      });

      // users/{uid} 문서 생성
      final userDocRef = _firestore.collection('Users').doc(user.uid);
      batch.set(userDocRef, {
        'email': ownerEmail,
        'storeId': storeId,
        'role': 'owner', // 역할: 사장
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Batch 커밋
      await batch.commit();

      return {
        "success": true,
        "message": "사장에게 새로운 계정이 성공적으로 등록되었습니다",
        "uid": user.uid,
        "storeId": storeId,
        "storeName": storeName,
      };
    } on FirebaseAuthException catch (e) {
      String message = "계정 생성 중 오류가 발생했습니다: ${e.message}";
      if (e.code == 'email-already-in-use') {
        message = "이미 사용 중인 이메일입니다.";
      } else if (e.code == 'weak-password') {
        message = "비밀번호가 너무 약합니다. 6자 이상 입력하세요.";
      } else if (e.code == 'invalid-email') {
        message = "유효하지 않은 이메일은 제외됩니다.";
      }
      return {"success": false, "message": message};
    } catch (e) {
      developer.log('Error creating store with owner: $e', name: 'StoreServer');
      return {"success": false, "message": "기타 오류가 발생했습니다: $e"};
    }
  }

  /// Store 파싱
  Store? _parseStore(String id, Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      return Store(
        id: id,
        name: data['name'] ?? '',
        isOpened: data['isOpened'] ?? false,
        notice: data['notice'] ?? '',
      );
    } catch (e) {
      developer.log('Error parsing store: $e', name: 'StoreServer');
      return null;
    }
  }
}
