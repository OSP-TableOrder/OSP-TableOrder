import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/provider/admin/system_admin_provider.dart';

class SystemAdminScreen extends StatefulWidget {
  const SystemAdminScreen({super.key});

  @override
  State<SystemAdminScreen> createState() => _SystemAdminScreenState();
}

class _SystemAdminScreenState extends State<SystemAdminScreen> {
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController ownerEmailController = TextEditingController();
  final TextEditingController ownerPasswordController = TextEditingController();
  final ValueNotifier<bool> isFilledNotifier = ValueNotifier(false);

  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    storeNameController.addListener(_updateFilled);
    ownerEmailController.addListener(_updateFilled);
    ownerPasswordController.addListener(_updateFilled);
  }

  void _updateFilled() {
    isFilledNotifier.value = storeNameController.text.trim().isNotEmpty &&
        ownerEmailController.text.trim().isNotEmpty &&
        ownerPasswordController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    storeNameController.dispose();
    ownerEmailController.dispose();
    ownerPasswordController.dispose();
    isFilledNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SystemAdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xfff4f6f9),
      appBar: AppBar(
        title: const Text('시스템 관리자'),
        backgroundColor: const Color(0xff2d7ff9),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(26),
            margin: const EdgeInsets.all(16),
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
                  "새 가게 및 사장 계정 등록",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: storeNameController,
                  decoration: InputDecoration(
                    labelText: "가게 이름",
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
                  controller: ownerEmailController,
                  decoration: InputDecoration(
                    labelText: "이메일",
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
                  controller: ownerPasswordController,
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
                        onPressed: (isFilled && !vm.isLoading)
                        ? () async {
                            final messenger = ScaffoldMessenger.of(context);

                            final success = await vm.createStoreWithOwner(
                              storeName: storeNameController.text.trim(),
                              ownerEmail: ownerEmailController.text.trim(),
                              ownerPassword: ownerPasswordController.text.trim(),
                            );

                            if (!mounted) return;

                            if (success) {
                              // 입력 창 초기화
                              storeNameController.clear();
                              ownerEmailController.clear();
                              ownerPasswordController.clear();
                              setState(() {});

                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('가게 및 사장 계정이 등록되었습니다.'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );
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
                            "등록",
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
      ),
    );
  }
}
