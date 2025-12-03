import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:table_order/provider/admin/staff_request_provider.dart';
import 'package:table_order/provider/admin/login_provider.dart';
import 'package:table_order/provider/admin/order_log_provider.dart' as order_log;
import 'package:table_order/provider/admin/order_provider.dart' as order_provider;

import 'package:table_order/widgets/admin/panel/call_staff_panel.dart';
import 'package:table_order/widgets/admin/panel/order_notification_panel.dart';

class AdminHeaderBar extends StatefulWidget {
  final VoidCallback onMenuPressed;

  const AdminHeaderBar({super.key, required this.onMenuPressed});

  @override
  State<AdminHeaderBar> createState() => _AdminHeaderBarState();
}

class _AdminHeaderBarState extends State<AdminHeaderBar> {
  late String _formattedTime = "";
  Timer? _timer;

  final _weekdayKorean = ['월', '화', '수', '목', '금', '토', '일'];

  OverlayEntry? _callOverlayEntry;
  OverlayEntry? _orderOverlayEntry;

  final GlobalKey _callIconKey = GlobalKey();
  final GlobalKey _orderIconKey = GlobalKey();

  // OverlayEntry가 Provider를 못 보는 문제 해결용 safe context
  late BuildContext _safeContext;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final weekday = _weekdayKorean[now.weekday - 1];

    final period = now.hour < 12 ? '오전' : '오후';
    int hour = now.hour % 12;
    if (hour == 0) hour = 12;

    final minute = now.minute.toString().padLeft(2, '0');

    setState(() {
      _formattedTime = "$month.$day ($weekday) $period $hour:$minute";
    });
  }

  double _calculateLeft(GlobalKey key, double panelWidth) {
    RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    double left = position.dx - (panelWidth - 30);

    if (left + panelWidth > screenWidth - 10) {
      left = screenWidth - panelWidth - 10;
    }
    if (left < 10) left = 10;

    return left;
  }

  // 직원 호출 패널
  void _showCallPanel() {
    if (_callOverlayEntry != null) return;

    final storeId = context.read<LoginProvider>().storeId;
    if (storeId == null) return;

    context.read<StaffRequestProvider>().loadLogs(storeId);

    const panelWidth = 260.0;

    final left = _calculateLeft(_callIconKey, panelWidth);
    final top =
        (_callIconKey.currentContext!.findRenderObject() as RenderBox)
            .localToGlobal(Offset.zero)
            .dy +
        32;

    _callOverlayEntry = OverlayEntry(
      builder: (_) => Consumer<StaffRequestProvider>(
        builder: (_, provider, __) {
          return Positioned(
            left: left,
            top: top,
            child: CallStaffPanel(
              callLogs: provider.logs,
              onClose: _closeCallPanel,
            ),
          );
        },
      ),
    );

    Overlay.of(_safeContext).insert(_callOverlayEntry!);
  }

  void _closeCallPanel() {
    _callOverlayEntry?.remove();
    _callOverlayEntry = null;
  }

  // 주문 알림 패널
  void _showOrderPanel() {
    if (_orderOverlayEntry != null) return;

    final tables = context.read<order_provider.OrderProvider>().tables;
    context.read<order_log.OrderLogProvider>().loadOrderLogs(tables);

    const panelWidth = 260.0;

    final left = _calculateLeft(_orderIconKey, panelWidth);
    final top =
        (_orderIconKey.currentContext!.findRenderObject() as RenderBox)
            .localToGlobal(Offset.zero)
            .dy +
        32;

    _orderOverlayEntry = OverlayEntry(
      builder: (_) => Consumer<order_log.OrderLogProvider>(
        builder: (_, provider, __) {
          return Positioned(
            left: left,
            top: top,
            child: OrderNotificationPanel(
              orderLogs: provider.orderLogs,
              onClose: _closeOrderPanel,
            ),
          );
        },
      ),
    );

    Overlay.of(_safeContext).insert(_orderOverlayEntry!);
  }

  void _closeOrderPanel() {
    _orderOverlayEntry?.remove();
    _orderOverlayEntry = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _closeCallPanel();
    _closeOrderPanel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _safeContext = context;

    return Container(
      height: 56,
      color: Colors.grey[850],
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 22),
            onPressed: widget.onMenuPressed,
          ),

          const Spacer(),

          Text(
            _formattedTime,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),

          const SizedBox(width: 6),

          // 직원호출 버튼
          IconButton(
            key: _callIconKey,
            icon: const Icon(Icons.back_hand, color: Colors.white, size: 20),
            onPressed: () {
              if (_callOverlayEntry == null) {
                _closeOrderPanel();
                _showCallPanel();
              } else {
                _closeCallPanel();
              }
            },
          ),

          // 주문 알림 버튼
          IconButton(
            key: _orderIconKey,
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              if (_orderOverlayEntry == null) {
                _closeCallPanel();
                _showOrderPanel();
              } else {
                _closeOrderPanel();
              }
            },
          ),
        ],
      ),
    );
  }
}
