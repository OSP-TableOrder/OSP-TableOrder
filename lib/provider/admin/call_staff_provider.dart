import 'package:flutter/material.dart';
import 'package:table_order/models/admin/call_staff_log.dart';
import 'package:table_order/service/admin/call_staff_service.dart';

class CallStaffProvider extends ChangeNotifier {
  final CallStaffService _service = CallStaffService();

  List<CallStaffLog> callLogs = [];

  Future<void> loadLogs(String storeId) async {
    callLogs = await _service.getLogs(storeId);
    notifyListeners();
  }

  Future<void> sendCallRequest({
    required String storeId,
    required String tableId,
    required String tableName,
    required String receiptId,
    required String message,
  }) async {
    await _service.sendCallRequest(
      storeId: storeId,
      tableId: tableId,
      tableName: tableName,
      receiptId: receiptId,
      message: message,
    );
  }

  Future<void> resolveCallRequests({
    required String storeId,
    required String tableId,
  }) async {
    await _service.resolveCallRequests(
      storeId: storeId,
      tableId: tableId,
    );
  }
}
