import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/provider/admin/login_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final ValueNotifier<bool> isFilledNotifier = ValueNotifier(false);

  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    idController.addListener(_updateFilled);
    pwController.addListener(_updateFilled);
  }

  void _updateFilled() {
    isFilledNotifier.value = idController.text.trim().isNotEmpty &&
        pwController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    idController.dispose();
    pwController.dispose();
    isFilledNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginProvider>();

    return Scaffold(
      backgroundColor: const Color(0xfff4f6f9),
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "로그인",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: idController,
                decoration: InputDecoration(
                  labelText: "아이디",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xff2d7ff9), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: pwController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "비밀번호",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xff2d7ff9), width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => isPasswordVisible = !isPasswordVisible);
                    },
                  ),
                ),
              ),

              if (vm.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  vm.errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 26),

              ValueListenableBuilder<bool>(
                valueListenable: isFilledNotifier,
                builder: (context, isFilled, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isFilled
                      ? () async {
                          final navigator = Navigator.of(context);

                          final ok = await vm.login(
                            idController.text.trim(),
                            pwController.text.trim(),
                          );

                          if (!mounted) return;

                          if (ok) {
                            // role에 따라 다른 화면으로 이동
                            final role = vm.role;
                            if (role == 'system_admin') {
                              navigator.pushNamed("/admin/system-admin");
                            } else {
                              navigator.pushNamed("/admin/home");
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2d7ff9),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: vm.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "로그인",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
