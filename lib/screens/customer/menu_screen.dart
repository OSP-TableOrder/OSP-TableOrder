import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/widgets/header_bar.dart';
import 'package:table_order/widgets/menu_item_card.dart';
import 'package:table_order/provider/customer/menu_provider.dart';
import 'package:table_order/provider/customer/cart_provider.dart';
import 'package:table_order/provider/customer/order_provider.dart';
import 'package:table_order/screens/customer/order_status_screen.dart';
import 'package:table_order/widgets/call_staff_modal/call_staff_modal.dart';
import 'package:table_order/provider/admin/call_staff_provider.dart';
import 'package:table_order/models/admin/call_staff_log.dart';
import 'package:table_order/routes/app_routes.dart';

class MenuScreen extends StatelessWidget {
  final int storeId;

  const MenuScreen({super.key, required this.storeId});

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
        final now = DateTime.now();
        final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        
        final log = CallStaffLog(
          table: '테이블',
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
    final orderProvider = context.read<OrderStatusViewModel>();

    final shouldLoad = !menuProvider.isLoading && menuProvider.menus.isEmpty;

    if (shouldLoad) {
      Future.microtask(() {
        final p = context.read<MenuProvider>();
        if (!p.isLoading && p.menus.isEmpty) {
          p.loadMenus(storeId);
        }
      });
    }

    // receiptId를 한 번만 설정
    if (orderProvider.receiptId != _receiptId) {
      orderProvider.setReceiptId(_receiptId);
    }

    final displayList = menuProvider.displayList;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: HeaderBar(
            title: '메뉴 주문하기',
            leftItem: TextButton(
              onPressed: () => _navigateToOrderStatus(context),
              child: Text(
                '주문현황',
                style: TextStyle(color: Colors.blue[700], fontSize: 16),
              ),
            ),
            rightItem: TextButton(
              onPressed: () => _showCallStaffDialog(context),
              child: Text(
                '직원호출',
                style: TextStyle(color: Colors.blue[700], fontSize: 16),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
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
                  return const SizedBox.shrink();
                },
              ),
      ),

      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final itemCount = cartProvider.itemCount;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              FloatingActionButton(
                onPressed: () => _navigateToCart(context),
                backgroundColor: const Color(0xFF6299FD),
                foregroundColor: Colors.white,
                child: const Icon(Icons.shopping_cart),
              ),
              if (itemCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      itemCount > 99 ? '99+' : '$itemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 10.0), // ⭐ 여백 개선
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}
