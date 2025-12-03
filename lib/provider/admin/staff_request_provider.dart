import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:table_order/models/admin/call_staff_log.dart';
import 'package:table_order/service/admin/staff_request_service.dart';

/// 직원 호출 도메인 Provider
/// 직원 호출 요청 목록과 UI 상태 관리
class StaffRequestProvider extends ChangeNotifier {
  final StaffRequestService _service = StaffRequestService();

  List<CallStaffLog> _logs = [];
  bool _loading = false;
  String? _error;

  // Getters
  List<CallStaffLog> get logs => _logs;
  bool get loading => _loading;
  String? get error => _error;

  /// 특정 가게의 대기 중인 직원 호출 요청 로드
  Future<void> loadLogs(String storeId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      developer.log(
        'Loading call request logs for storeId=$storeId',
        name: 'StaffRequestProvider',
      );

      _logs = await _service.getLogs(storeId);

      developer.log(
        'Loaded ${_logs.length} call request logs',
        name: 'StaffRequestProvider',
      );

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load call request logs: $e';
      developer.log(_error!, name: 'StaffRequestProvider');
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 직원 호출 요청 생성
  Future<void> addCallRequest({
    required String storeId,
    required String tableId,
    required String tableName,
    required String receiptId,
    required String message,
  }) async {
    try {
      _error = null;

      developer.log(
        'Adding call request: tableId=$tableId, receiptId=$receiptId',
        name: 'StaffRequestProvider',
      );

      await _service.addCallLog(
        storeId: storeId,
        tableId: tableId,
        tableName: tableName,
        receiptId: receiptId,
        message: message,
      );

      developer.log(
        'Call request added successfully',
        name: 'StaffRequestProvider',
      );

      // 호출 요청 생성 후 로그 새로 로드
      await loadLogs(storeId);
    } catch (e) {
      _error = 'Failed to add call request: $e';
      developer.log(_error!, name: 'StaffRequestProvider');
      notifyListeners();
    }
  }

  /// 직원 호출 요청 해결 (pending -> resolved)
  Future<void> resolveCallRequests({
    required String storeId,
    required String tableId,
  }) async {
    try {
      _error = null;

      developer.log(
        'Resolving call requests for tableId=$tableId',
        name: 'StaffRequestProvider',
      );

      await _service.resolveCallRequests(
        storeId: storeId,
        tableId: tableId,
      );

      developer.log(
        'Call requests resolved successfully',
        name: 'StaffRequestProvider',
      );

      // 호출 요청 해결 후 로그 새로 로드
      await loadLogs(storeId);
    } catch (e) {
      _error = 'Failed to resolve call requests: $e';
      developer.log(_error!, name: 'StaffRequestProvider');
      notifyListeners();
    }
  }

  /// 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
