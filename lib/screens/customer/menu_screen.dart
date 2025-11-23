import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/widgets/menu_item_card.dart';
import 'package:table_order/provider/customer/menu_provider.dart';

class MenuScreen extends StatelessWidget {
  final int storeId;

  const MenuScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();

    final shouldLoad = !menuProvider.isLoading && menuProvider.menus.isEmpty;

    if (shouldLoad) {
      Future.microtask(() {
        final p = context.read<MenuProvider>();
        if (!p.isLoading && p.menus.isEmpty) {
          p.loadMenus(storeId);
        }
      });
    }

    final displayList = menuProvider.displayList;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      
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

      
      body: Column(
        children: [
          HeaderBar(
            title: "메뉴 주문하기",
            leftItem: TextButton(
              onPressed: () {
                // TODO: 주문현황 페이지로 이동
                // Navigator.push(context, MaterialPageRoute(builder: (_) => OrderStatusScreen()));
                print('주문현황 클릭');
              },
              child: Text(
                "주문현황",
                style: TextStyle(color: Colors.blue[700], fontSize: 16),
              ),
            ),
            rightItem: TextButton(
              onPressed: () {
                // TODO: 직원호출 페이지로 이동
                // Navigator.push(context, MaterialPageRoute(builder: (_) => StaffCallScreen()));
                print("직원호출 클릭");
              },
              child: Text(
                "직원호출",
                style: TextStyle(color: Colors.blue[700], fontSize: 16),
              ),
            ),
          ),

          Expanded(
            child: (menuProvider.isLoading && displayList.isEmpty)
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final item = displayList[index];

                    if (item is String) {
                      return _buildCategoryHeader(item);
                    } else if (item is Menu) {
                      return MenuItemCard(item: item);
                    }
                    return SizedBox.shrink();
                  },
                ),
          ),
        ],
      ),

      body: (menuProvider.isLoading && displayList.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final item = displayList[index];

                if (item is String) {
                  return _buildCategoryHeader(item);
                } else if (item is Menu) {
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
