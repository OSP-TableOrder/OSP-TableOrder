import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/models/admin/store_info.dart';
import 'package:table_order/provider/admin/login_provider.dart';
import 'package:table_order/provider/admin/store_provider.dart';
import 'package:table_order/widgets/admin/store_description/edit_store_info_modal.dart';

class StoreInfoArea extends StatefulWidget {
  const StoreInfoArea({super.key});

  @override
  State<StoreInfoArea> createState() => _StoreInfoAreaState();
}

class _StoreInfoAreaState extends State<StoreInfoArea> {
  @override
  void initState() {
    super.initState();
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
    final storeInfo = provider.storeInfo;
    final storeId = context.read<LoginProvider>().storeId;

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xffe9eef3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "가게정보 수정",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: storeId == null
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (_) => EditStoreInfoModal(
                            storeInfo: storeInfo ?? StoreInfoModel(storeName: '', notice: ''), // 현재 모델 전달
                            onSubmit: (StoreInfoModel newInfo) {
                              // 수정된 모델을 Provider로 전달
                              provider.updateStoreInfo(
                                storeId: storeId.toString(),
                                name: newInfo.storeName,
                                notice: newInfo.notice,
                              );
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
                child: const Text("정보 수정"),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("가게 이름", storeInfo?.storeName ?? ''),
                const Divider(height: 32, color: Color(0xffe9eef3)),
                _buildInfoRow("공지사항", storeInfo?.notice ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content.isEmpty ? "등록된 정보가 없습니다." : content,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
