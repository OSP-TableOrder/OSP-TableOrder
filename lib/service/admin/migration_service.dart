import 'package:table_order/server/admin_server/migration_server.dart';

/// 마이그레이션 서비스
/// Orders 컬렉션 분리 마이그레이션 작업 관리
class MigrationService {
  final MigrationServer _server = MigrationServer();

  /// 마이그레이션 실행
  /// Orders → Receipts, Orders 컬렉션 분리
  Future<Map<String, dynamic>> executeMigration() async {
    return await _server.executeMigration();
  }

  /// 마이그레이션 상태 확인
  Future<Map<String, int>> getMigrationStatus() async {
    return await _server.getMigrationStatus();
  }

  /// Orders → Receipts 마이그레이션
  Future<void> migrateOrdersToReceipts() async {
    return await _server.migrateOrdersToReceipts();
  }

  /// CallRequests에 receiptId 추가
  Future<void> addReceiptIdToCallRequests() async {
    return await _server.addReceiptIdToCallRequests();
  }
}
