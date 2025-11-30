import 'package:flutter/material.dart';
import 'package:table_order/models/admin/table_model.dart';
import 'package:table_order/service/admin/table_connect_service.dart';

class TableConnectProvider extends ChangeNotifier {
  final TableConnectService _service = TableConnectService();

  List<TableModel> _tables = [];
  List<TableModel> get tables => _tables;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadTables(String storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tables = await _service.getTables(storeId);
    } catch (e) {
      _error = 'Failed to load tables: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTable({
    required String storeId,
    required String name,
  }) async {
    try {
      _error = null;
      await _service.addTable(storeId: storeId, name: name);
      await loadTables(storeId); // 목록 갱신
    } catch (e) {
      _error = 'Failed to add table: $e';
      notifyListeners();
    }
  }

  Future<void> updateTable({
    required String id,
    required String name,
    required String storeId,
  }) async {
    try {
      _error = null;
      await _service.updateTable(id: id, name: name);
      await loadTables(storeId); // 목록 갱신
    } catch (e) {
      _error = 'Failed to update table: $e';
      notifyListeners();
    }
  }

  Future<void> deleteTable({
    required String id,
    required String storeId,
  }) async {
    try {
      _error = null;
      await _service.deleteTable(id);
      await loadTables(storeId); // 목록 갱신
    } catch (e) {
      _error = 'Failed to delete table: $e';
      notifyListeners();
    }
  }
}
