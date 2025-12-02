import 'package:flutter/foundation.dart';
import 'package:table_order/models/customer/store.dart';
import 'package:table_order/service/customer/store_service.dart';

class StoreProvider with ChangeNotifier {
  final StoreService _service = StoreService();

  List<Store> _stores = [];
  Store? _currentStore;
  bool _isLoading = false;
  String? _error;

  List<Store> get stores => _stores;
  Store? get currentStore => _currentStore;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 모든 Store 조회
  Future<void> loadStores() async {
    _isLoading = true;
    notifyListeners();

    _stores = await _service.getStores();

    _isLoading = false;
    notifyListeners();
  }

  /// UID로 Store 정보 로드
  Future<void> loadStoreByUid(String uid) async {
    _isLoading = true;
    notifyListeners();

    _currentStore = await _service.getStoreByUid(uid);

    _isLoading = false;
    notifyListeners();
  }

  /// Store ID로 조회
  Future<void> loadStoreById(String storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentStore = await _service.getStore(storeId);
      if (_currentStore == null) {
        _error = '가게 정보를 찾을 수 없습니다.';
      }
    } catch (e) {
      _error = 'Failed to load store: $e';
      _currentStore = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 에러 상태 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
