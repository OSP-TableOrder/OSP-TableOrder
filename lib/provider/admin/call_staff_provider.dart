import 'package:flutter/material.dart';
import 'package:table_order/models/admin/call_staff_log.dart';
import 'package:table_order/service/admin/call_staff_service.dart';

class CallStaffProvider extends ChangeNotifier {
  final CallStaffService _service = CallStaffService();

  List<CallStaffLog> callLogs = [];

  Future<void> loadLogs() async {
    callLogs = await _service.getLogs();
    notifyListeners();
  }

  Future<void> addLog(CallStaffLog log) async {
    await _service.addLog(log);
    await loadLogs();
  }
}
