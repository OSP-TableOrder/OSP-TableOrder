import 'package:flutter/material.dart';
import 'package:table_order/server/admin_server/auth_server.dart';

class LoginProvider extends ChangeNotifier {
  final AuthServer _server = AuthServer();

  String? errorMessage;
  bool isLoading = false;
  Map<String, dynamic>? userData;

  /// Firebase 이메일/비밀번호로 로그인
  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _server.login(email, password);

    isLoading = false;

    if (!result["success"]) {
      errorMessage = result["message"];
      notifyListeners();
      return false;
    }

    userData = result;
    notifyListeners();
    return true;
  }

  /// 로그아웃
  Future<void> logout() async {
    await _server.logout();
    userData = null;
    errorMessage = null;
    notifyListeners();
  }

  /// 현재 로그인한 사용자 정보 가져오기
  Future<void> fetchCurrentUser() async {
    final user = await _server.getCurrentUser();
    userData = user;
    notifyListeners();
  }

  /// 로그인 여부
  bool get isLoggedIn => userData != null;

  /// 사용자 UID
  String? get uid => userData?['uid'] as String?;

  /// 사용자 이름
  String? get userName => userData?['userName'] as String?;

  /// Store ID (Firestore 자동 생성 ID)
  String? get storeId {
    final id = userData?['storeId'];
    if (id is String) return id;
    if (id is int) return id.toString();
    return null;
  }

  /// 사용자 역할 (system_admin, owner)
  String? get role => userData?['role'] as String?;
}
