import 'package:table_order/server/admin_server/call_staff_server.dart';
import 'package:table_order/models/admin/call_staff_log.dart';

class CallStaffService {
  final CallStaffServerStub _server = CallStaffServerStub();

  Future<List<CallStaffLog>> getLogs() => _server.fetchCallLogs();
  Future<void> addLog(CallStaffLog log) => _server.addCallLog(log);
}
