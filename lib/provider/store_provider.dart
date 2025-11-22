import 'package:flutter/foundation.dart';

import 'package:table_order/models/store.dart';
import 'package:table_order/service/store_service.dart';

class StoreProvider with ChangeNotifier {
  final StoreService _storeService = StoreService();
  late List<Store> _stores;

  List<Store> get stores => _stores;

  // TODO : 아래 로직들 비동기 처리 필요

  StoreProvider() {
    // 생성자에서 데이터 초기화
    _stores = _storeService.fetchAllStores();
  }

  // 특정 ID로 가게 찾기
  Store? findById(int id) => _storeService.fetchStoreById(id);

  // 나중에 서버 데이터 새로고침용
  void refreshStores() {
    _stores = _storeService.fetchAllStores();
    notifyListeners();
  }
}
