import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:table_order/models/admin/store_info.dart';
import 'package:table_order/models/admin/table_model.dart';
import 'package:table_order/service/admin/store_service.dart';

/// 가게 도메인 Provider
/// 가게 정보와 테이블의 UI 상태 관리
class StoreProvider extends ChangeNotifier {
  final StoreService _service = StoreService();

  StoreInfoModel? _storeInfo;
  List<TableModel> _tables = [];
  bool _loading = false;
  String? _error;

  // Getters
  StoreInfoModel? get storeInfo => _storeInfo;
  List<TableModel> get tables => _tables;
  bool get loading => _loading;
  String? get error => _error;

  // ============= Store 관련 메서드 =============

  /// 가게와 테이블 데이터 로드
  Future<void> loadStoreData(String storeId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      developer.log(
        'Loading store data for storeId=$storeId',
        name: 'StoreProvider',
      );

      final storeInfoFuture = _service.getStoreInfo(storeId);
      final tablesFuture = _service.getTables(storeId);

      _storeInfo = await storeInfoFuture;
      _tables = await tablesFuture;

      developer.log(
        'Loaded store info and ${_tables.length} tables',
        name: 'StoreProvider',
      );

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load store data: $e';
      developer.log(_error!, name: 'StoreProvider');
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 가게 정보 수정
  Future<void> updateStoreInfo({
    required String storeId,
    required String name,
    required String notice,
  }) async {
    try {
      _error = null;
      await _service.updateStoreInfo(
        storeId: storeId,
        name: name,
        notice: notice,
      );

      developer.log(
        'Store info updated: name=$name',
        name: 'StoreProvider',
      );

      // 가게 정보 수정 후 데이터 새로 로드
      await loadStoreData(storeId);
    } catch (e) {
      _error = 'Failed to update store info: $e';
      developer.log(_error!, name: 'StoreProvider');
      notifyListeners();
    }
  }

  // ============= Table 관련 메서드 =============

  /// 테이블 추가
  Future<void> addTable({
    required String storeId,
    required String name,
  }) async {
    try {
      _error = null;
      await _service.createTable(
        storeId: storeId,
        name: name,
      );

      developer.log(
        'Table added: name=$name',
        name: 'StoreProvider',
      );

      // 테이블 추가 후 테이블 목록 새로 로드
      await loadStoreData(storeId);
    } catch (e) {
      _error = 'Failed to add table: $e';
      developer.log(_error!, name: 'StoreProvider');
      notifyListeners();
    }
  }

  /// 테이블 수정
  Future<void> updateTable({
    required String id,
    required String name,
    required String storeId,
  }) async {
    try {
      _error = null;
      await _service.updateTable(
        id: id,
        name: name,
      );

      developer.log(
        'Table updated: id=$id, name=$name',
        name: 'StoreProvider',
      );

      // 테이블 수정 후 테이블 목록 새로 로드
      await loadStoreData(storeId);
    } catch (e) {
      _error = 'Failed to update table: $e';
      developer.log(_error!, name: 'StoreProvider');
      notifyListeners();
    }
  }

  /// 테이블 삭제
  Future<void> deleteTable({
    required String id,
    required String storeId,
  }) async {
    try {
      _error = null;
      await _service.deleteTable(id);

      developer.log(
        'Table deleted: id=$id',
        name: 'StoreProvider',
      );

      // 테이블 삭제 후 테이블 목록 새로 로드
      await loadStoreData(storeId);
    } catch (e) {
      _error = 'Failed to delete table: $e';
      developer.log(_error!, name: 'StoreProvider');
      notifyListeners();
    }
  }

  /// 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
