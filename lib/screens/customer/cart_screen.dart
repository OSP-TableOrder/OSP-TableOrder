import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:table_order/models/customer/cart_item.dart';
import 'package:table_order/widgets/cart_item_card.dart';
import 'package:table_order/widgets/header_bar.dart';
import 'package:table_order/provider/customer/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void _showOrderConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '주문을 완료하시겠어요?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('장바구니에 담긴 메뉴로 주문이 생성됩니다.'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('주문이 완료되었습니다!')));
            },
            child: const Text('주문하기', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.items;
    final totalPrice = cartProvider.totalPrice;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(
              title: "장바구니",
              leftItem: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios),
              ),
            ),

          // 화면 나머지 영역
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
