import 'dart:async';
import 'package:table_order/models/admin/call_staff_log.dart';

class CallStaffServerStub {
  final List<CallStaffLog> _logs = [
    CallStaffLog(table: "1번", message: "물티슈", time: "12:30"),
    CallStaffLog(table: "2번", message: "수저", time: "12:31"),
    CallStaffLog(table: "3번", message: "물", time: "12:32"),
  ];

  Future<List<CallStaffLog>> fetchCallLogs() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<CallStaffLog>.from(_logs);
  }

  Future<void> addCallLog(CallStaffLog log) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logs.insert(0, log);
  }
}
