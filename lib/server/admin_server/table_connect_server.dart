import 'dart:async';
import 'package:table_order/models/admin/table_model.dart';

class TableConnectServerStub {
  static const String _currentStoreId = "store_12345";

  static final List<TableModel> _tables = [
    const TableModel(id: "t1", name: "1번 테이블", storeId: _currentStoreId),
    const TableModel(id: "t2", name: "2번 테이블", storeId: _currentStoreId),
    const TableModel(id: "t3", name: "3번 테이블", storeId: _currentStoreId),
    const TableModel(id: "t4", name: "4번 테이블", storeId: _currentStoreId),
  ];

  Future<List<TableModel>> fetchTables() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_tables);
  }

  Future<void> addTable(String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newId =
        "t${_tables.length + 1}_${DateTime.now().millisecondsSinceEpoch}";

    _tables.add(TableModel(id: newId, name: name, storeId: _currentStoreId));
  }

  Future<void> deleteTable(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _tables.removeWhere((t) => t.id == id);
  }
}
