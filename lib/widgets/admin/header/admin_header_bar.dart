import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:table_order/provider/admin/call_staff_provider.dart';
import 'package:table_order/provider/admin/order_log_provider.dart';

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

  late BuildContext _safeContext;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    // 화면 시작 시 데이터를 불러와서, 초기 알림 상태를 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CallStaffProvider>().loadLogs();
        context.read<OrderProvider>().loadOrderLogs();
      }
    });
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

    if (mounted) {
      setState(() {
        _formattedTime = "$month.$day ($weekday) $period $hour:$minute";
      });
    }
  }

  double _calculateLeft(GlobalKey key, double panelWidth) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return 10.0;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    double left = position.dx - (panelWidth - 30);

    if (left + panelWidth > screenWidth - 10) {
      left = screenWidth - panelWidth - 10;
    }
    if (left < 10) left = 10;

    return left;
  }

  // 직원 호출 패널 열기
  void _showCallPanel() async {
    if (_callOverlayEntry != null) return;

    // 데이터 로드
    await context.read<CallStaffProvider>().loadLogs();

    // 패널을 열었으므로 빨간 점 제거 (읽음 처리)
    if (mounted) {
      context.read<CallStaffProvider>().markAsRead();
    }

    const panelWidth = 260.0;
    final left = _calculateLeft(_callIconKey, panelWidth);

    final renderBox =
        _callIconKey.currentContext?.findRenderObject() as RenderBox?;
    final double top = (renderBox?.localToGlobal(Offset.zero).dy ?? 0) + 32;

    _callOverlayEntry = OverlayEntry(
      builder: (_) => Consumer<CallStaffProvider>(
        builder: (_, provider, __) {
          return Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: CallStaffPanel(
                callLogs: provider.callLogs,
                onClose: _closeCallPanel,
              ),
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

  // 주문 알림 패널 열기
  void _showOrderPanel() async {
    if (_orderOverlayEntry != null) return;

    await context.read<OrderProvider>().loadOrderLogs();

    // 패널을 열었으므로 빨간 점 제거 (읽음 처리)
    if (mounted) {
      context.read<OrderProvider>().markAsRead();
    }

    const panelWidth = 260.0;
    final left = _calculateLeft(_orderIconKey, panelWidth);

    final renderBox =
        _orderIconKey.currentContext?.findRenderObject() as RenderBox?;
    final double top = (renderBox?.localToGlobal(Offset.zero).dy ?? 0) + 32;

    _orderOverlayEntry = OverlayEntry(
      builder: (_) => Consumer<OrderProvider>(
        builder: (_, provider, __) {
          return Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: OrderNotificationPanel(
                orderLogs: provider.orderLogs,
                onClose: _closeOrderPanel,
              ),
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

    // 알림 상태 구독 (빨간 점 표시용)
    final bool hasUnreadOrder = context.watch<OrderProvider>().hasUnreadAlert;
    final bool hasUnreadCall = context
        .watch<CallStaffProvider>()
        .hasUnreadCalls;

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

          // 1. 직원 호출 버튼
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                key: _callIconKey,
                icon: const Icon(
                  Icons.back_hand,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  if (_callOverlayEntry == null) {
                    _closeOrderPanel();
                    _showCallPanel();
                  } else {
                    _closeCallPanel();
                  }
                },
              ),
              if (hasUnreadCall)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          // 2. 주문 알림 버튼
          Stack(
            clipBehavior: Clip.none,
            children: [
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
              if (hasUnreadOrder)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
