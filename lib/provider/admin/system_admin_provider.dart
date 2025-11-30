import 'package:flutter/material.dart';
import 'package:table_order/service/customer/store_service.dart';

class SystemAdminProvider extends ChangeNotifier {
  final StoreService _storeService = StoreService();

  String? errorMessage;
  String? successMessage;
  bool isLoading = false;

  /// 가게와 사장 계정 등록
  Future<bool> createStoreWithOwner({
    required String storeName,
    required String ownerEmail,
    required String ownerPassword,
  }) async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final result = await _storeService.createStoreWithOwner(
        storeName: storeName,
        ownerEmail: ownerEmail,
        ownerPassword: ownerPassword,
      );

      isLoading = false;

      if (!result.success) {
        errorMessage = result.message;
        notifyListeners();
        return false;
      }

      successMessage = result.message;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = "등록 중 오류가 발생했습니다: $e";
      notifyListeners();
      return false;
    }
  }

  /// 에러 메시지 초기화
  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }
}
