import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:table_order/service/admin/migration_service.dart';

/// 마이그레이션 도메인 Provider
/// Firestore 데이터 마이그레이션 작업 관리
class MigrationProvider extends ChangeNotifier {
  final MigrationService _service = MigrationService();

  Map<String, int>? _status;
  bool _loading = false;
  String? _error;
  String? _successMessage;

  // Getters
  Map<String, int>? get status => _status;
  bool get loading => _loading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  /// 마이그레이션 상태 확인
  Future<void> checkMigrationStatus() async {
    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      developer.log(
        'Checking migration status',
        name: 'MigrationProvider',
      );

      _status = await _service.getMigrationStatus();

      developer.log(
        'Migration status: $_status',
        name: 'MigrationProvider',
      );

      notifyListeners();
    } catch (e) {
      _error = 'Failed to check migration status: $e';
      developer.log(_error!, name: 'MigrationProvider');
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 마이그레이션 실행
  Future<void> executeMigration() async {
    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      developer.log(
        'Executing migration: Orders → Receipts',
        name: 'MigrationProvider',
      );

      final result = await _service.executeMigration();

      if (result['success'] == true) {
        _successMessage = result['message'] ?? 'Migration completed successfully';
        _status = (result['endStatus'] as Map<String, dynamic>?)?.cast<String, int>();

        developer.log(
          _successMessage!,
          name: 'MigrationProvider',
        );
      } else {
        _error = result['message'] ?? 'Migration failed for unknown reason';
        developer.log(_error!, name: 'MigrationProvider');
      }

      notifyListeners();
    } catch (e) {
      _error = 'Error executing migration: $e';
      developer.log(_error!, name: 'MigrationProvider');
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 성공 메시지 초기화
  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }
}
