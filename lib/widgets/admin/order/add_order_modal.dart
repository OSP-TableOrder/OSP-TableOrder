// lib/widgets/admin/table/menu_selection_modal.dart

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/provider/app_state_provider.dart';
import 'package:table_order/service/admin/product_service.dart';

class AddOrderModal extends StatefulWidget {
  final String? storeId;

  const AddOrderModal({
    super.key,
    this.storeId,
  });

  @override
  State<AddOrderModal> createState() => _AddOrderModalState();
}

class _AddOrderModalState extends State<AddOrderModal> {
  final ProductService _productService = ProductService();
  late Future<List<Map<String, dynamic>>> _menusFuture;
  List<Map<String, dynamic>> _menus = [];

  // 선택된 수량을 저장하는 맵 (key: 메뉴이름, value: 수량)
  final Map<String, int> _selectedCounts = {};

  @override
  void initState() {
    super.initState();
    // storeId를 가져와서 메뉴 목록 로드
    String? storeId = widget.storeId;

    // 매개변수로 받은 storeId가 없으면 AppStateProvider에서 가져옴
    if (storeId == null) {
      final appState = context.read<AppStateProvider>();
      storeId = appState.storeId;
    }

    developer.log('AddOrderModal initState - storeId: $storeId', name: 'AddOrderModal');

    if (storeId != null) {
      _menusFuture = _productService.getProductsByStore(storeId);
    } else {
      developer.log('AddOrderModal initState - storeId is null!', name: 'AddOrderModal');
      _menusFuture = Future.value([]);
    }
  }

  void _increaseCount(String name) {
    setState(() {
      _selectedCounts[name] = (_selectedCounts[name] ?? 0) + 1;
    });
  }

  void _decreaseCount(String name) {
    setState(() {
      final current = _selectedCounts[name] ?? 0;
      if (current > 0) {
        _selectedCounts[name] = current - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 선택된 총 개수 계산
    int totalItems = _selectedCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.8, // 화면 80% 높이
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "메뉴 추가",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 메뉴 리스트 (스크롤 가능)
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _menusFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  developer.log('FutureBuilder error: ${snapshot.error}', name: 'AddOrderModal');
                  return Center(
                    child: Text('메뉴 로드 실패: ${snapshot.error}'),
                  );
                }

                _menus = snapshot.data ?? [];
                developer.log('FutureBuilder completed with ${_menus.length} menus', name: 'AddOrderModal');
                if (_menus.isEmpty) {
                  return const Center(
                    child: Text('사용 가능한 메뉴가 없습니다.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _menus.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final menu = _menus[index];
                    final name = menu['name'];
                    final price = menu['price'];
                    final count = _selectedCounts[name] ?? 0;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: count > 0 ? Colors.blue : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: count > 0
                        ? Colors.blue.withValues(alpha: 0.05)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "$price원",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 수량 조절 버튼
                      Row(
                        children: [
                          IconButton(
                            onPressed: count > 0
                                ? () => _decreaseCount(name)
                                : null,
                            icon: Icon(
                              Icons.remove_circle,
                              color: count > 0
                                  ? Colors.grey
                                  : Colors.grey.shade300,
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              "$count",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _increaseCount(name),
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
                  },
                );
              },
            ),
          ),

          // 하단 추가 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: totalItems > 0
                    ? () {
                        // 선택된 메뉴만 필터링해서 리턴
                        List<Map<String, dynamic>> result = [];
                        final selectedMenus = _menus
                            .where((m) {
                              final name = m['name'] ?? '';
                              return (_selectedCounts[name] ?? 0) > 0;
                            })
                            .toList();

                        for (final menu in selectedMenus) {
                          final name = menu['name'];
                          final count = _selectedCounts[name] ?? 0;
                          if (count > 0) {
                            result.add({
                              "menu": menu,  // 전체 메뉴 객체 저장
                              "quantity": count,
                            });
                          }
                        }
                        Navigator.pop(context, result); // 결과 전달하며 닫기
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text("$totalItems개 메뉴 추가하기"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
