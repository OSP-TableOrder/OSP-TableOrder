class AuthServerStub {
  Future<Map<String, dynamic>> login(String id, String pw) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (id != "admin" || pw != "1234") {
      return {"success": false, "message": "아이디 또는 비밀번호가 올바르지 않습니다."};
    }

    return {"success": true, "message": "로그인 성공", "userName": "admin"};
  }
}
