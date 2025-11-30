// lib/widgets/admin/table/menu_selection_modal.dart

import 'package:flutter/material.dart';

class AddOrderModal extends StatefulWidget {
  const AddOrderModal({super.key});

  @override
  State<AddOrderModal> createState() => _AddOrderModalState();
}

class _AddOrderModalState extends State<AddOrderModal> {
  // 전체 메뉴 데이터
  final List<Map<String, dynamic>> availableMenus = [
    {"name": "아메리카노", "price": 3000},
    {"name": "카페라떼", "price": 3500},
    {"name": "카페모카", "price": 4000},
    {"name": "딸기라떼", "price": 6000},
    {"name": "레몬에이드", "price": 6000},
    {"name": "블루베리스무디", "price": 7000},
  ];

  // 선택된 수량을 저장하는 맵 (key: 메뉴이름, value: 수량)
  final Map<String, int> _selectedCounts = {};

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
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: availableMenus.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final menu = availableMenus[index];
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
                        _selectedCounts.forEach((name, count) {
                          if (count > 0) {
                            final menuInfo = availableMenus.firstWhere(
                              (element) => element['name'] == name,
                            );
                            result.add({
                              "name": name,
                              "price": menuInfo['price'],
                              "quantity": count,
                            });
                          }
                        });
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
