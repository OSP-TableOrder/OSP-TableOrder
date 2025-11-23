import 'package:table_order/server/admin_server/auth_server.dart';

class AuthService {
  final _server = AuthServerStub();

  Future<LoginResult> login(String id, String pw) async {
    final res = await _server.login(id, pw);
    return LoginResult(
      success: res["success"],
      message: res["message"],
      userName: res["userName"],
    );
  }
}

class LoginResult {
  final bool success;
  final String message;
  final String? userName;

  LoginResult({required this.success, required this.message, this.userName});
}
