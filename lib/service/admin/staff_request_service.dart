import 'package:table_order/models/admin/call_staff_log.dart';
import 'package:table_order/server/admin_server/staff_request_repository.dart';

/// 직원 호출 도메인 Service
/// 직원 호출 요청의 비즈니스 로직 처리
class StaffRequestService {
  final StaffRequestRepository _repository = StaffRequestRepository();

  /// 특정 가게의 대기 중인 직원 호출 로그 조회
  Future<List<CallStaffLog>> getLogs(String storeId) async {
    return await _repository.fetchCallLogs(storeId);
  }

  /// 직원 호출 요청 생성
  Future<void> addCallLog({
    required String storeId,
    required String tableId,
    required String tableName,
    required String receiptId,
    required String message,
  }) async {
    return await _repository.addCallLog(
      storeId: storeId,
      tableId: tableId,
      tableName: tableName,
      receiptId: receiptId,
      message: message,
    );
  }

  /// 직원 호출 요청 해결
  Future<void> resolveCallRequests({
    required String storeId,
    required String tableId,
  }) async {
    return await _repository.resolveCallLogs(
      storeId: storeId,
      tableId: tableId,
    );
  }
}
