class LoginModel {
  final bool success;
  final String message;
  final String? userName;

  LoginModel({required this.success, required this.message, this.userName});
}
