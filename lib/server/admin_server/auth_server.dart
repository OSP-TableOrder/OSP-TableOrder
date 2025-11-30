import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthServer {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firebase 로그인
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) {
        return {
          "success": false,
          "message": "사용자 정보를 가져오는데 실패했어요. 다시 시도해 주세요!",
        };
      }

      // Firestore에서 사용자 정보 조회
      final DocumentSnapshot userDoc = await _firestore
          .collection('Users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return {"success": false, "message": "매장 승인 대기 중이에요. 승인이 되면 알려드릴게요!"};
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? 'Admin';
      final storeId = userData['storeId'];
      final role = userData['role'] ?? 'owner'; // 기본값: owner

      return {
        "success": true,
        "message": "로그인 성공",
        "uid": user.uid,
        "email": user.email,
        "userName": userName,
        "storeId": storeId,
        "role": role,
      };
    } on FirebaseAuthException catch (e) {
      String message = "로그인 중 오류가 발생했습니다: $e";
      if (e.code == 'invalid-credential') {
        message = "아이디 또는 비밀번호가 잘못되었습니다.";
      }
      return {"success": false, "message": message};
    } catch (e) {
      return {"success": false, "message": "로그인 중 오류가 발생했습니다: $e"};
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  /// 현재 로그인한 사용자 정보
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final DocumentSnapshot userDoc = await _firestore
          .collection('Users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;

      return {
        "uid": user.uid,
        "email": user.email,
        "userName": userData['name'] ?? 'Admin',
        "storeId": userData['storeId'],
        "role": userData['role'] ?? 'owner',
      };
    } catch (e) {
      developer.log('Error getting current user: $e', name: 'AuthServer');
      return null;
    }
  }
}
