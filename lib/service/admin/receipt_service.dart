import 'package:table_order/models/admin/table_order_info.dart';
import 'package:table_order/server/admin_server/receipt_repository.dart';

/// 영수증(Receipt) 도메인 Service
/// 테이블 영수증의 조회 및 정산 비즈니스 로직 처리
class ReceiptService {
  final ReceiptRepository _repository = ReceiptRepository();

  /// 특정 가게의 미정산 영수증을 테이블별로 그룹화하여 조회
  Future<List<TableOrderInfo>> getUnpaidReceiptsByStore(String storeId) async {
    return await _repository.fetchUnpaidReceiptsByStore(storeId);
  }

  /// 영수증 상태 변경 (unpaid -> paid)
  Future<bool> updateReceiptStatus({
    required String receiptId,
    required String newStatus,
  }) async {
    return await _repository.updateReceiptStatus(
      receiptId: receiptId,
      newStatus: newStatus,
    );
  }

  /// 특정 영수증 조회
  Future<Map<String, dynamic>?> getReceiptById(String receiptId) async {
    return await _repository.getReceiptById(receiptId);
  }

  /// 영수증 생성
  Future<String?> createReceipt({
    required String storeId,
    required String tableId,
    required int totalPrice,
  }) async {
    return await _repository.createReceipt(
      storeId: storeId,
      tableId: tableId,
      totalPrice: totalPrice,
    );
  }

  /// 영수증에 메뉴 추가 (메뉴를 Receipt.menus[] 배열에 추가)
  Future<bool> addMenuToReceipt({
    required String receiptId,
    required Map<String, dynamic> menuData,
  }) async {
    return await _repository.addMenuToReceipt(
      receiptId: receiptId,
      menuData: menuData,
    );
  }
}
