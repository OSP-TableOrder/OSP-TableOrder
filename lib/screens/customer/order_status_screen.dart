import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:table_order/utils/won_formatter.dart';
import 'package:table_order/models/customer/order_menu.dart';
import 'package:table_order/provider/customer/order_provider.dart';
import 'package:table_order/widgets/order_status/order_menu_card.dart';
import 'package:table_order/widgets/confirm_modal/confirm_modal.dart';
import 'package:table_order/widgets/header_bar.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key, required this.receiptId});
  final String receiptId;

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final snackBar = ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('주문 내역을 불러오고 있습니다...')));

      final viewModel = context.read<OrderStatusViewModel>();
      await viewModel.loadInitial(receiptId: widget.receiptId);
      if (!mounted) return;
      snackBar.close();

      unawaited(_pollLoop(viewModel));
    });
  }

  Future<void> _pollLoop(OrderStatusViewModel viewModel) async {
    // 3초마다 새로고침
    while (_alive) {
      await Future.delayed(const Duration(seconds: 3));
      if (!_alive) break;
      await viewModel.refresh();
    }
  }

  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  void _toast(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? null : Colors.red[600],
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provider에서 viewModel 가져오기
    final viewModel = context.watch<OrderStatusViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: HeaderBar(
            title: "주문현황",
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
              child: Builder(
                builder: (context) {
                  if (viewModel.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final order = viewModel.order;
                  final menus = order.menus;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // 주문 번호
                        Text(
                          'no.${order.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 주문 메뉴 목록
                        Expanded(
                          child: menus.isEmpty
                              ? const Center(
                                  child: Text('주문 내역이 없습니다. 메뉴를 주문해주세요!'),
                                )
                              : ListView.separated(
                                  itemCount: menus.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, idx) {
                                    final OrderMenu menu = menus[idx];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: OrderMenuCard(
                                        orderMenu: menu,
                                        onTapDelete: menu.isCancelable
                                            ? () async {
                                                final ok = await showConfirmModal(
                                                  context,
                                                  title: '주문 메뉴 취소',
                                                  description: '해당 메뉴를 취소하시겠습니까?',
                                                  cancelText: '취소',
                                                  actionText: '확인',
                                                  onActionAsync: () async {
                                                    await viewModel.cancelMenu(
                                                      menu.id,
                                                    );
                                                  },
                                                );
                                                if (ok == true) {
                                                  _toast('주문 메뉴가 성공적으로 취소되었습니다.');
                                                }
                                              }
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 총 가격 섹션 - body 내 하단
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '총 가격',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Consumer<OrderStatusViewModel>(
                        builder: (context, viewModel, _) {
                          return Text(
                            formatWon(viewModel.totalPrice),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      const Text('원', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
