import 'package:flutter/material.dart';
import 'package:table_order/models/admin/table_model.dart';
import 'package:table_order/service/admin/table_connect_service.dart';

class TableConnectProvider extends ChangeNotifier {
  final TableConnectService _service = TableConnectService();

  List<TableModel> _tables = [];
  List<TableModel> get tables => _tables;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadTables() async {
    _isLoading = true;
    notifyListeners(); // 로딩 시작 알림

    try {
      _tables = await _service.getTables();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTable(String name) async {
    await _service.addTable(name);
    await loadTables(); // 목록 갱신
  }

  Future<void> deleteTable(String id) async {
    await _service.deleteTable(id);
    await loadTables(); // 목록 갱신
  }
}
