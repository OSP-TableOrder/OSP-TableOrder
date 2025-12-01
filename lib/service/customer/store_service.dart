import 'package:table_order/models/customer/store.dart';
import 'package:table_order/server/customer_server/store_server.dart';

class StoreService {
  final StoreServer _server = StoreServer();

  /// 모든 Store 조회
  Future<List<Store>> getStores() async {
    return await _server.fetchStores();
  }

  /// Store ID로 조회
  Future<Store?> getStore(String id) async {
    return await _server.findById(id);
  }

  /// UID로 Store 정보 조회
  Future<Store?> getStoreByUid(String uid) async {
    return await _server.fetchStoreByUid(uid);
  }

  /// 가게와 사장 계정 생성
  Future<StoreCreationResult> createStoreWithOwner({
    required String storeName,
    required String ownerEmail,
    required String ownerPassword,
  }) async {
    final res = await _server.createStoreWithOwner(
      storeName: storeName,
      ownerEmail: ownerEmail,
      ownerPassword: ownerPassword,
    );

    return StoreCreationResult(
      success: res["success"],
      message: res["message"],
      uid: res["uid"],
      storeId: res["storeId"],
      storeName: res["storeName"],
    );
  }
}

/// 가게 생성 결과
class StoreCreationResult {
  final bool success;
  final String message;
  final String? uid;
  final String? storeId; // Firestore 자동 생성 ID
  final String? storeName;

  StoreCreationResult({
    required this.success,
    required this.message,
    this.uid,
    this.storeId,
    this.storeName,
  });
}
