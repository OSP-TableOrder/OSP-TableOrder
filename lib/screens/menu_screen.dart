import 'package:flutter/material.dart';

import 'package:table_order/models/menu.dart';
import 'package:table_order/widgets/menu_item_card.dart';

// 목업 데이터 (나중에 API 연동 시 service/provider 등으로 이동)
final List<Map<String, dynamic>> mockMenuData = [
  {
    'category': '메뉴',
    'items': [
      Menu(
        id: 1,
        name: '메뉴1',
        description: '메뉴1 입니다.',
        price: 10000,
        isSoldOut: false,
        isRecommended: true,
      )
    ],
  },
  {
    'category': '뉴메',
    'items': [
      Menu(
        id: 2,
        name: '뉴메뉴메',
        description: '뉴메뉴메뉴메',
        price: 10000,
        isSoldOut: true,
        isRecommended: false,
      ),
      Menu(
        id: 3,
        name: '메뉴메뉴',
        description: '메뉴메뉴메뉴',
        price: 22222,
        isSoldOut: false,
        isRecommended: false,
      )
    ],
  },
  {
    'category': '음메',
    'items': [
      Menu(
        id: 4,
        name: '음메음메음메',
        description: '염소 아닙니다',
        price: 9999,
        isSoldOut: true,
        isRecommended: true,
      ),
    ],
  },
];

class MenuScreen extends StatelessWidget {
  MenuScreen({Key? key}) : super(key: key);

  // 카테고리와 메뉴 아이템을 하나의 리스트로 평탄화
  final List<dynamic> displayList = [];

  void _flattenData() {
    // TODO: 데이터가 매번 빌드되지 않도록 생성자나 initState에서 한 번만 호출하는 것을 권장
    if (displayList.isNotEmpty) return;

    for (var categoryData in mockMenuData) {
      displayList.add(categoryData['category'] as String);
      displayList.addAll(categoryData['items'] as List<Menu>);
    }
  }

  @override
  Widget build(BuildContext context) {
    _flattenData();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
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
        leadingWidth: 100,
        title: Text(
          '메뉴 주문하기',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 장바구니 페이지로 이동
          // Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen()));
          print('장바구니 클릭');
        },
        backgroundColor: Color(0xFF6299FD),
        foregroundColor: Colors.white,
        child: Icon(Icons.shopping_cart),
      ),
      body: ListView.builder(
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final item = displayList[index];

          if (item is String) {
            // 아이템이 String이면 카테고리 헤더
            return _buildCategoryHeader(item);
          } else if (item is Menu) {
            // 아이템이 MenuItem이면 메뉴 카드
            return MenuItemCard(item: item);
          }
          return SizedBox.shrink();
        },
      ),
    );
  }

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