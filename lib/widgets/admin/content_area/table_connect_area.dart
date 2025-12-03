import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/provider/admin/login_provider.dart';
import 'package:table_order/provider/admin/store_provider.dart';
import 'package:table_order/provider/admin/order_provider.dart';
import 'package:table_order/widgets/admin/qr/qr_dialog.dart';
import 'package:table_order/widgets/admin/table/add_table_modal.dart';

class TableConnectArea extends StatefulWidget {
  const TableConnectArea({super.key});

  @override
  State<TableConnectArea> createState() => _TableConnectAreaState();
}

class _TableConnectAreaState extends State<TableConnectArea> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 테이블 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeId = context.read<LoginProvider>().storeId;
      if (storeId != null) {
        context.read<StoreProvider>().loadStoreData(storeId.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();
    final tables = provider.tables;

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xffe9eef3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 헤더 및 추가 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "테이블 관리",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () {
                  final storeId = context.read<LoginProvider>().storeId;
                  if (storeId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Store ID를 찾을 수 없습니다.')),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (_) => AddTableModal(
                      onSubmit: (name) async {
                        // DB에 테이블 추가
                        await provider.addTable(
                          storeId: storeId.toString(),
                          name: name,
                        );

                        // 홈 화면 목록 갱신
                        if (context.mounted) {
                          await context
                              .read<OrderProvider>()
                              .loadTables(storeId.toString());
                        }
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2d7ff9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("+ 테이블 추가"),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 테이블 리스트 그리드
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisExtent: 180,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: tables.length,
                    itemBuilder: (context, index) {
                      final table = tables[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.table_restaurant,
                              size: 40,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              table.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // QR 코드 버튼
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          QrCodeDialog(table: table),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffe9eef3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.qr_code, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          "QR 발급",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 삭제 버튼
                                Material(
                                  color: Colors.transparent,
                                  child: IconButton(
                                    onPressed: () async {
                                      final storeId =
                                          context.read<LoginProvider>().storeId;
                                      if (storeId == null) return;

                                      // DB에서 삭제
                                      await provider.deleteTable(
                                        id: table.id,
                                        storeId: storeId.toString(),
                                      );

                                      // 홈 화면 목록 갱신
                                      if (context.mounted) {
                                        await context
                                            .read<OrderProvider>()
                                            .loadTables(storeId.toString());
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: "삭제",
                                    splashRadius: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
