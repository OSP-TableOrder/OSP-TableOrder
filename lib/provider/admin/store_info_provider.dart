import 'package:flutter/material.dart';
import 'package:table_order/models/admin/store_info.dart';
import 'package:table_order/service/admin/store_info_service.dart';

class StoreInfoProvider extends ChangeNotifier {
  final StoreInfoService _service = StoreInfoService();

  StoreInfoModel _storeInfo = StoreInfoModel.initial();

  StoreInfoModel get storeInfo => _storeInfo;

  // 초기 데이터 로드
  Future<void> loadStoreInfo() async {
    _storeInfo = await _service.getStoreInfo();
    notifyListeners();
  }

  // 정보 수정
  Future<void> updateStoreInfo(StoreInfoModel newInfo) async {
    await _service.updateStoreInfo(newInfo.storeName, newInfo.notice);

    _storeInfo = newInfo;
    notifyListeners();
  }
}
