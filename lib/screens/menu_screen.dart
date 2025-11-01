import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../widgets/menu_item_card.dart';

final List<Map<String, dynamic>> mockMenuData = [
  {
    'category': '메뉴',
    'items': [MenuItem(name: '메뉴1', description: '메뉴1 입니다.', price: 10000)],
  },
  {
    'category': '뉴메',
    'items': [MenuItem(name: '뉴메뉴메', description: '뉴메뉴메뉴메', price: 10000)],
  },
  {
    'category': '음메',
    'items': [MenuItem(name: '음메음메음메', description: '염소 아닙니다', price: 9999)],
  },
];

class MenuScreen extends StatelessWidget {
  MenuScreen({Key? key}) : super(key: key);

  // 1. 데이터를 '평탄화'된 리스트로 변환
  final List<dynamic> displayList = [];

  void _flattenData() {
    // 앱 빌드 시 한 번만 실행되도록 생성자 등에서 처리하는 것이 좋음
    // 여기서는 설명을 위해 간단히 처리
    if (displayList.isNotEmpty) return; // 이미 평탄화했다면 스킵

    for (var categoryData in mockMenuData) {
      displayList.add(
        categoryData['category'] as String,
      ); // 카테고리 이름 (String) 추가
      displayList.addAll(
        categoryData['items'] as List<MenuItem>,
      ); // 메뉴 아이템 (MenuItem) 리스트 추가
    }
  }

  @override
  Widget build(BuildContext context) {
    _flattenData(); // 데이터 평탄화 실행

    return Scaffold(
      backgroundColor: Colors.grey[100], // 배경색
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        // 1. 좌측 네비게이션
        leading: TextButton(
          onPressed: () {
            // TODO: 주문현황 페이지로 이동
            // Navigator.push(context, MaterialPageRoute(builder: (_) => OrderStatusScreen()));
            print('주문현황 클릭');
          },
          child: Text(
            '주문현황',
            style: TextStyle(color: Colors.blue[700], fontSize: 16),
          ),
        ),
        leadingWidth: 100, // 텍스트가 잘리지 않게
        // 2. 중앙 타이틀
        title: Text(
          '메뉴 주문하기',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // 3. 우측 네비게이션
        actions: [
          TextButton(
            onPressed: () {
              // TODO: 직원호출 페이지로 이동
              // Navigator.push(context, MaterialPageRoute(builder: (_) => StaffCallScreen()));
              print('직원호출 클릭');
            },
            child: Text(
              '직원호출',
              style: TextStyle(color: Colors.blue[700], fontSize: 16),
            ),
          ),
        ],
      ),
      // 4. 플로팅 액션 버튼 (장바구니)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 장바구니 페이지로 이동
          // Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen()));
          print('장바구니 클릭');
        },
        child: Icon(Icons.shopping_cart),
      ),
      // 5. 본문 (메뉴 리스트)
      body: ListView.builder(
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final item = displayList[index];

          if (item is String) {
            // 타입이 String이면, 카테고리 헤더
            return _buildCategoryHeader(item);
          } else if (item is MenuItem) {
            // 타입이 MenuItem이면, 메뉴 아이템 카드
            return MenuItemCard(item: item);
          }
          return SizedBox.shrink(); // 비어있는 위젯
        },
      ),
    );
  }

  // 카테고리 헤더 위젯
  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}
