import 'package:flutter/material.dart';
import 'package:table_order/server/admin_server/auth_server.dart';

class LoginProvider extends ChangeNotifier {
  final AuthServerStub _server = AuthServerStub();

  String? errorMessage;
  bool isLoading = false;

  Future<bool> login(String id, String pw) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _server.login(id, pw);

    isLoading = false;

    if (!result["success"]) {
      errorMessage = result["message"];
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }
}
