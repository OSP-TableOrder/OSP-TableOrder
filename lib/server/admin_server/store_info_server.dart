import 'dart:async';

import 'package:table_order/models/admin/store_info.dart';

class StoreInfoServerStub {
  StoreInfoModel _storeInfo = const StoreInfoModel(
    storeName: "맛있는 떡볶이 구미점",
    notice: "재료 소진 시 조기 마감될 수 있습니다.",
  );

  // 가게 정보 조회
  Future<StoreInfoModel> fetchStoreInfo() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _storeInfo;
  }

  // 가게 정보 수정
  Future<void> updateStoreInfo(String name, String notice) async {
    await Future.delayed(const Duration(milliseconds: 200));

    _storeInfo = _storeInfo.copyWith(storeName: name, notice: notice);
  }
}
