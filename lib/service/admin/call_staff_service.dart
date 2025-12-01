import 'package:table_order/server/admin_server/call_staff_server.dart';
import 'package:table_order/models/admin/call_staff_log.dart';

class CallStaffService {
  final CallStaffServer _server = CallStaffServer();

  Future<List<CallStaffLog>> getLogs(String storeId) =>
      _server.fetchCallLogs(storeId);

  Future<void> sendCallRequest({
    required String storeId,
    required String tableId,
    required String tableName,
    required String receiptId,
    required String message,
  }) async {
    await _server.addCallLog(
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
    await _server.resolveCallLogs(
      storeId: storeId,
      tableId: tableId,
    );
  }
}
