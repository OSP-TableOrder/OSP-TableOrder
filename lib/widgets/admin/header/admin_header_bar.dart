import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_order/widgets/admin/panel/call_staff_panel.dart';
import 'package:table_order/widgets/admin/panel/order_notification_panel.dart';

class AdminHeaderBar extends StatefulWidget {
  final VoidCallback onMenuPressed;
  const AdminHeaderBar({super.key, required this.onMenuPressed});

  @override
  State<AdminHeaderBar> createState() => _AdminHeaderBarState();
}

class _AdminHeaderBarState extends State<AdminHeaderBar> {
  late String _formattedTime;
  late Timer _timer;

  final _weekdayKorean = ['월', '화', '수', '목', '금', '토', '일'];

  // 직원 호출 데이터
  final List<Map<String, String>> callLogs = [
    {"table": "1층 1호 테이블", "message": "물티슈", "time": "4분 전"},
    {"table": "1층 2호 테이블", "message": "수저", "time": "5분 전"},
  ];

  // 주문 알림 데이터
  final List<Map<String, String>> orderLogs = [
    {"table": "1번 테이블", "order": "아메리카노 2개", "time": "14:18"},
    {"table": "4번 테이블", "order": "카페라떼 1개", "time": "14:19"},
  ];

  OverlayEntry? _callOverlayEntry;
  OverlayEntry? _orderOverlayEntry;

  final GlobalKey _callIconKey = GlobalKey();
  final GlobalKey _orderIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  DateTime _getKoreaTime() {
    return DateTime.now().toUtc().add(const Duration(hours: 9));
  }

  void _updateTime() {
    final now = _getKoreaTime();
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

  // 패널 위치 계산
  double _calculateLeft(GlobalKey key, double panelWidth) {
    RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    final screenWidth = MediaQuery.of(context).size.width;
    double left = position.dx - (panelWidth - 30);

    // 오른쪽 화면 밖 방지
    if (left + panelWidth > screenWidth - 10) {
      left = screenWidth - panelWidth - 10;
    }

    // 왼쪽 화면 밖 방지
    if (left < 10) left = 10;

    return left;
  }

  void _showCallPanel() {
    if (_callOverlayEntry != null) return;

    const double panelWidth = 260;
    final left = _calculateLeft(_callIconKey, panelWidth);

    RenderBox renderBox =
        _callIconKey.currentContext!.findRenderObject() as RenderBox;
    final top = renderBox.localToGlobal(Offset.zero).dy + 32;

    _callOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        child: CallStaffPanel(callLogs: callLogs, onClose: _closeCallPanel),
      ),
    );

    Overlay.of(context).insert(_callOverlayEntry!);
  }

  void _closeCallPanel() {
    _callOverlayEntry?.remove();
    _callOverlayEntry = null;
  }

  void _showOrderPanel() {
    if (_orderOverlayEntry != null) return;

    const double panelWidth = 260;
    final left = _calculateLeft(_orderIconKey, panelWidth);

    RenderBox renderBox =
        _orderIconKey.currentContext!.findRenderObject() as RenderBox;
    final top = renderBox.localToGlobal(Offset.zero).dy + 32;

    _orderOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        child: OrderNotificationPanel(
          orderLogs: orderLogs,
          onClose: _closeOrderPanel,
        ),
      ),
    );

    Overlay.of(context).insert(_orderOverlayEntry!);
  }

  void _closeOrderPanel() {
    _orderOverlayEntry?.remove();
    _orderOverlayEntry = null;
  }

  @override
  void dispose() {
    _timer.cancel();
    _closeCallPanel();
    _closeOrderPanel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: Colors.grey[850],
      padding: const EdgeInsets.symmetric(horizontal: 6), // ← 오른쪽 패딩 축소

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
