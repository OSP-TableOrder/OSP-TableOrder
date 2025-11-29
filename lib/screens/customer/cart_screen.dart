import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:table_order/widgets/customer/cart_item_card.dart';
import 'package:table_order/widgets/customer/header_bar.dart';
import 'package:table_order/provider/customer/cart_provider.dart';
import 'package:table_order/widgets/customer/confirm_modal/confirm_modal.dart';
import 'package:table_order/models/customer/order_menu.dart';
import 'package:table_order/models/customer/order_menu_status.dart';
import 'package:table_order/provider/customer/order_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Future<void> _showOrderConfirmDialog() async {
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderStatusViewModel>();

    final cartItems = cartProvider.items.toList();

    // 모달 표시
    final result = await showConfirmModal(
      context,
      title: '주문을 완료하시겠어요?',
      description: '장바구니에 담긴 메뉴로 주문이 생성됩니다.',
      cancelText: '취소',
      actionText: '주문하기',
      onActionAsync: () async {
        // 1) CartItem → OrderMenu 변환 후 서버에 추가
        for (final cartItem in cartItems) {
          final orderMenu = OrderMenu(
            id: DateTime.now().millisecondsSinceEpoch, // 임시 id
            status: OrderMenuStatus.ordered,
            quantity: cartItem.quantity,
            completedCount: 0,
            menu: cartItem.menu,
          );

          await orderProvider.addMenu(orderMenu);
        }

        // 2) 장바구니 비우기
        cartProvider.clear();
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('주문이 완료되었습니다!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.items;
    final totalPrice = cartProvider.totalPrice;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: HeaderBar(
            title: "장바구니",
            leftItem: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: cartItems.isEmpty
                  ? const Center(
                      child: Text(
                        '장바구니가 비어있습니다.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView(
                      children: cartItems
                          .map(
                            (item) => CartItemCard(
                              item: item,
                              onRemove: () {
                                cartProvider.removeItem(item.id);
                              },
                            ),
                          )
                          .toList(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                onPressed: cartItems.isEmpty ? null : _showOrderConfirmDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[500],
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '${cartItems.length}개 주문하기 - $totalPrice원',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
