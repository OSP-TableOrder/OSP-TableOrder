import 'package:table_order/models/admin/store_info.dart';
import 'package:table_order/models/admin/table_model.dart';
import 'package:table_order/server/admin_server/store_repository.dart';

/// 가게 도메인 Service
/// 가게 정보와 테이블의 비즈니스 로직 처리
class StoreService {
  final StoreRepository _repository = StoreRepository();

  // ============= Store 관련 메서드 =============

  /// 특정 가게의 정보 조회
  Future<StoreInfoModel> getStoreInfo(String storeId) async {
    return await _repository.fetchStoreInfo(storeId);
  }

  /// 가게 정보 수정
  Future<void> updateStoreInfo({
    required String storeId,
    required String name,
    required String notice,
  }) async {
    return await _repository.updateStoreInfo(
      storeId: storeId,
      name: name,
      notice: notice,
    );
  }

  // ============= Table 관련 메서드 =============

  /// 특정 가게의 모든 테이블 조회
  Future<List<TableModel>> getTables(String storeId) async {
    return await _repository.fetchTables(storeId);
  }

  /// 테이블 생성
  Future<void> createTable({
    required String storeId,
    required String name,
  }) async {
    return await _repository.addTable(
      storeId: storeId,
      name: name,
    );
  }

  /// 테이블 수정
  Future<void> updateTable({
    required String id,
    required String name,
  }) async {
    return await _repository.updateTable(
      id: id,
      name: name,
    );
  }

  /// 테이블 삭제
  Future<void> deleteTable(String id) async {
    return await _repository.deleteTable(id);
  }
}
