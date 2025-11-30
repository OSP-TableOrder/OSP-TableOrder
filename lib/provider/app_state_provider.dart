import 'dart:async';

import 'package:flutter/material.dart';

import 'package:table_order/service/customer/table_service.dart';

class AppStateProvider extends ChangeNotifier {
  final TableService _tableService = TableService();
  String? _storeId;
  String? _tableId;
  String? _tableName;
  bool _tableNameLoading = false;

  /// Store ID 조회
  String? get storeId => _storeId;

  /// Table ID 조회
  String? get tableId => _tableId;

  /// Table 이름 조회 (없으면 tableId 사용)
  String? get tableName => _tableName;

  /// Store ID와 Table ID 설정
  void setStoreAndTable({
    required String storeId,
    required String tableId,
    String? tableName,
  }) {
    _storeId = storeId;
    _tableId = tableId;
    _tableName = tableName;
    notifyListeners();

    if (_tableName == null || _tableName!.isEmpty) {
      unawaited(_loadTableName());
    }
  }

  /// Store ID만 설정
  void setStoreId(String storeId) {
    _storeId = storeId;
    notifyListeners();
  }

  /// Table ID 설정
  void setTableId(String tableId) {
    _tableId = tableId;
    notifyListeners();

    if (_tableName == null || _tableName!.isEmpty) {
      unawaited(_loadTableName());
    }
  }

  /// Table 이름 설정
  void setTableName(String? tableName) {
    _tableName = tableName;
    notifyListeners();
  }

  Future<void> _loadTableName() async {
    if (_tableId == null || _tableNameLoading) return;
    _tableNameLoading = true;
    try {
      final name = await _tableService.getTableName(_tableId!);
      if (name != null && name.isNotEmpty) {
        _tableName = name;
        notifyListeners();
      }
    } finally {
      _tableNameLoading = false;
    }
  }

  Future<void> ensureTableNameLoaded() async {
    if (_tableName != null || _tableId == null) return;
    await _loadTableName();
  }

  /// 초기화
  void clear() {
    _storeId = null;
    _tableId = null;
    _tableName = null;
    _tableNameLoading = false;
    notifyListeners();
  }

  /// 상태 확인
  bool get isReady => _storeId != null && _tableId != null;
}
