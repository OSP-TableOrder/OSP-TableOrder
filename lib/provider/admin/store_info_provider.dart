import 'package:flutter/material.dart';
import 'package:table_order/models/admin/store_info.dart';
import 'package:table_order/service/admin/store_info_service.dart';

class StoreInfoProvider extends ChangeNotifier {
  final StoreInfoService _service = StoreInfoService();

  StoreInfoModel _storeInfo = StoreInfoModel.initial();
  StoreInfoModel get storeInfo => _storeInfo;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// 가게 정보 로드
  Future<void> loadStoreInfo(String storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _storeInfo = await _service.getStoreInfo(storeId);
    } catch (e) {
      _error = 'Failed to load store info: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 가게 정보 수정
  Future<void> updateStoreInfo({
    required String storeId,
    required StoreInfoModel newInfo,
  }) async {
    try {
      _error = null;
      await _service.updateStoreInfo(
        storeId: storeId,
        name: newInfo.storeName,
        notice: newInfo.notice,
      );
      _storeInfo = newInfo;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update store info: $e';
      notifyListeners();
    }
  }
}
