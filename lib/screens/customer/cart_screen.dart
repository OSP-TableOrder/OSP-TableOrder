import 'package:flutter/material.dart';

import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/models/customer/cart_item.dart';
import 'package:table_order/widgets/cart_item_card.dart';
import 'package:table_order/widgets/header_bar.dart';

// TODO - 카트 아이템 목업 - 추후 제거
final List<CartItem> mockCartItems = [
  CartItem(
    id: 1,
    menu: Menu(
      id: 1,
      storeId: 2,
      name: '메뉴1',
      description: '메뉴1입니다.',
      price: 10000,
      isSoldOut: false,
      isRecommended: true,
    ),
    quantity: 1,
  ),
  CartItem(
    id: 2,
    menu: Menu(
      id: 2,
      storeId: 2,
      name: '메뉴2',
      description: '메뉴2입니다.',
      price: 13000,
      isSoldOut: false,
      isRecommended: true,
    ),
    quantity: 4,
  ),
];

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
    final totalPrice = mockCartItems.fold(
      0,
      (sum, item) => sum + (item.menu.price * item.quantity),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
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
            child: ListView(
              children: mockCartItems
                  .map(
                    (item) => CartItemCard(
                      item: item,
                      onRemove: () {
                        setState(() {
                          mockCartItems.remove(item);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              onPressed: mockCartItems.isEmpty ? null : _showOrderConfirmDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[500],
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '${mockCartItems.length}개 주문하기 - $totalPrice원',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
