import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/widgets/header_bar.dart';
import 'package:table_order/widgets/menu_item_card.dart';
import 'package:table_order/provider/customer/menu_provider.dart';
import 'package:table_order/screens/customer/order_status_screen.dart';
import 'package:table_order/widgets/call_staff_modal/call_staff_modal.dart';
import 'package:table_order/provider/admin/call_staff_provider.dart';
import 'package:table_order/models/admin/call_staff_log.dart';
import 'package:table_order/routes/app_routes.dart';

class MenuScreen extends StatelessWidget {
  final int storeId;

  const MenuScreen({super.key, required this.storeId});

  // TODO: receiptId는 나중에 실제 데이터와 연동 시 수정 필요
  // 현재는 임시로 하드코딩, 나중에 Provider나 상태 관리로 받아올 수 있음
  String get _receiptId => '438';

  void _navigateToOrderStatus(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderStatusScreen(receiptId: _receiptId),
      ),
    );
  }

  Future<void> _showCallStaffDialog(BuildContext context) async {
    final callStaffProvider = context.read<CallStaffProvider>();
    
    await showCallStaffDialog(
      context,
      receiptId: _receiptId,
      onSubmit: (receiptId, message, items) async {
        // TODO: table 정보는 나중에 실제 데이터와 연동 시 수정 필요
        final now = DateTime.now();
        final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        
        final log = CallStaffLog(
          table: '테이블', // TODO: 실제 테이블 정보로 교체 필요
          message: message,
          time: timeString,
        );
        
        await callStaffProvider.addLog(log);
      },
    );
  }

  void _navigateToCart(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.cart);
  }

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: TextButton(
          onPressed: () => _navigateToOrderStatus(context),
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
            onPressed: () => _showCallStaffDialog(context),
            child: Text(
              '직원호출',
              style: TextStyle(color: Colors.blue[700], fontSize: 16),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCart(context),
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
