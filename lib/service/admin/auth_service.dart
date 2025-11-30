import 'package:table_order/server/admin_server/auth_server.dart';

class AuthService {
  final _server = AuthServer();

  Future<LoginResult> login(String email, String password) async {
    final res = await _server.login(email, password);
    return LoginResult(
      success: res["success"],
      message: res["message"],
      userName: res["userName"],
      uid: res["uid"],
      storeId: res["storeId"],
    );
  }

  Future<void> logout() => _server.logout();

  Future<Map<String, dynamic>?> getCurrentUser() => _server.getCurrentUser();
}

class LoginResult {
  final bool success;
  final String message;
  final String? userName;
  final String? uid;
  final int? storeId;

  LoginResult({
    required this.success,
    required this.message,
    this.userName,
    this.uid,
    this.storeId,
  });
}
