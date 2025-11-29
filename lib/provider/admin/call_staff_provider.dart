import 'package:flutter/material.dart';
import 'package:table_order/models/admin/call_staff_log.dart';
import 'package:table_order/service/admin/call_staff_service.dart';

class CallStaffProvider extends ChangeNotifier {
  final CallStaffService _service = CallStaffService();

  List<CallStaffLog> callLogs = [];

  // 읽지 않은 호출 알림 상태
  bool _hasUnreadCalls = false;
  bool get hasUnreadCalls => _hasUnreadCalls;

  Future<void> loadLogs() async {
    // 서버(서비스)에서 최신 로그를 가져옴
    final newLogs = await _service.getLogs();

    // 기존보다 개수가 늘어났으면 새로운 호출이 온 것으로 간주하여 빨간 점 켜기
    if (newLogs.length > callLogs.length) {
      _hasUnreadCalls = true;
    }

    callLogs = newLogs;
    notifyListeners();
  }

  Future<void> addLog(CallStaffLog log) async {
    await _service.addLog(log);
    await loadLogs();
  }

  // 알림 확인 처리 (빨간 점 끄기)
  void markAsRead() {
    _hasUnreadCalls = false;
    notifyListeners();
  }
}
