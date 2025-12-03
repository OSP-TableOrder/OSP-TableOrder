import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:table_order/widgets/customer/cart_item_card.dart';
import 'package:table_order/widgets/customer/header_bar.dart';
import 'package:table_order/provider/customer/cart_provider.dart';
import 'package:table_order/widgets/customer/confirm_modal/confirm_modal.dart';
import 'package:table_order/models/customer/order_menu.dart';
import 'package:table_order/models/common/order_menu_status.dart';
import 'package:table_order/provider/customer/order_provider.dart';
import 'package:table_order/provider/app_state_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isProcessing = false;

  Future<void> _showOrderConfirmDialog() async {
    if (_isProcessing) return;
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderStatusViewModel>();
    final appState = context.read<AppStateProvider>();

    final cartItems = cartProvider.items.toList();
    final storeId = appState.storeId;
    final tableId = appState.tableId;

    // 총 수량 계산
    final totalQuantity = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    if (storeId == null || storeId.isEmpty || tableId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('가게 정보가 없습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (totalQuantity == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('주문할 메뉴가 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 모달 열기 전 처리 중 플래그 설정 (중복 요청 방지)
    setState(() => _isProcessing = true);

    try {
      final confirmed = await showConfirmModal(
        context,
        title: '주문을 완료하시겠어요?',
        description: '장바구니에 담긴 메뉴를 주문에 추가합니다.',
        cancelText: '취소',
        actionText: '주문하기',
        onActionAsync: () async {
          try {
            developer.log(
              'Confirming order for tableId=$tableId (items=${cartItems.length})',
              name: 'CartScreen',
            );

            // 1) Receipt 확보: 기존 영수증이 있으면 사용, 없으면 생성
            if (orderProvider.receiptId == null) {
              await orderProvider.initializeReceipt(
                storeId: storeId,
                tableId: tableId,
              );
            }

            if (orderProvider.receiptId == null) {
              throw Exception('주문 생성에 실패했습니다.');
            }

            // 2) Order 생성
            await orderProvider.createOrder(storeId: storeId, tableId: tableId);

            // 3) CartItem → OrderMenu 변환 후 주문에 추가
            for (final cartItem in cartItems) {
              final orderMenu = OrderMenu(
                id: '',
                status: OrderMenuStatus.ordered,
                quantity: cartItem.quantity,
                completedCount: 0,
                menu: cartItem.menu,
              );

              developer.log(
                'Adding menu to current order: ${cartItem.menu.name} x ${cartItem.quantity}',
                name: 'CartScreen',
              );
              await orderProvider.addMenu(orderMenu);
            }

            developer.log(
              'Order submitted successfully',
              name: 'CartScreen',
            );
          } catch (e) {
            developer.log('Failed to submit order: $e', name: 'CartScreen');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('주문 처리 중 오류가 발생했습니다. 다시 시도해주세요.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      );

      if (confirmed == true && mounted) {
        // 1) 즉시 장바구니 비우기
        cartProvider.clear();

        // 2) 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주문이 추가되었습니다!')),
        );

        // 3) 즉시 메인 화면으로 이동
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      // 모달 닫은 후 처리 중 플래그 해제
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.items;
    final totalQuantity = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HeaderBar(
        title: "장바구니",
        leftItem: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios),
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
                      children: cartItems.map((item) {
                        return CartItemCard(
                          item: item,
                          onRemove: () {
                            cartProvider.removeItem(item.id);
                          },
                          onIncrement: () {
                            cartProvider.incrementQuantity(item.id);
                          },
                          onDecrement: () {
                            cartProvider.decrementQuantity(item.id);
                          },
                        );
                      }).toList(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                onPressed: (cartItems.isEmpty || _isProcessing) ? null : _showOrderConfirmDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[500],
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isProcessing ? '주문 처리 중...' : '${totalQuantity}개 주문하기',
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
