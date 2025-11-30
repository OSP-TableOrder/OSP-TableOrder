import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/provider/app_state_provider.dart';
import 'package:table_order/widgets/role_box.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _showUserInputDialog(BuildContext context) {
    final storeIdController = TextEditingController();
    final tableIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가게 및 테이블 정보 입력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: storeIdController,
              decoration: const InputDecoration(
                labelText: 'Store ID',
                hintText: '가게 ID를 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tableIdController,
              decoration: const InputDecoration(
                labelText: 'Table ID',
                hintText: '테이블 ID를 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final storeId = storeIdController.text.trim();
              final tableId = tableIdController.text.trim();

              if (storeId.isEmpty || tableId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모든 필드를 입력해주세요.')),
                );
                return;
              }

              // AppState에 저장
              context.read<AppStateProvider>().setStoreAndTable(
                    storeId: storeId,
                    tableId: tableId,
                  );

              Navigator.pop(context);

              // 메뉴 화면으로 이동
              Navigator.pushNamed(
                context,
                '/user/menuList',
                arguments: {'storeId': storeId, 'tableId': tableId},
              );
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RoleBox(
              title: "사장",
              color: Colors.orange.shade300,
              onTap: () {
                Navigator.pushNamed(context, '/admin/login');
              },
            ),

            const SizedBox(width: 20),

            RoleBox(
              title: "사용자",
              color: Colors.blue.shade300,
              onTap: () {
                _showUserInputDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
