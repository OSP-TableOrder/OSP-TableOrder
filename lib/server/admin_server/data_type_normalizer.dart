/// Firestore 데이터 타입 정규화 유틸리티
/// 혼재된 타입 (int/String, null/empty 등)을 통일된 형식으로 변환
class DataTypeNormalizer {
  /// storeId를 항상 String으로 반환
  /// int 타입이면 String으로 변환, null이면 기본값 반환
  static String normalizeStoreId(dynamic storeId, {String defaultValue = ''}) {
    if (storeId == null) return defaultValue;
    if (storeId is String) return storeId;
    if (storeId is int) return storeId.toString();
    return defaultValue;
  }

  /// tableId를 항상 String으로 반환
  static String normalizeTableId(dynamic tableId, {String defaultValue = ''}) {
    if (tableId == null) return defaultValue;
    if (tableId is String) return tableId;
    if (tableId is int) return tableId.toString();
    return defaultValue;
  }

  /// price를 항상 int로 반환
  /// String이면 int로 파싱, null이면 0 반환
  static int normalizePrice(dynamic price, {int defaultValue = 0}) {
    if (price == null) return defaultValue;
    if (price is int) return price;
    if (price is String) {
      final parsed = int.tryParse(price);
      return parsed ?? defaultValue;
    }
    if (price is double) return price.toInt();
    return defaultValue;
  }

  /// 숫자를 항상 int로 반환 (수량, 개수 등)
  static int normalizeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    if (value is double) return value.toInt();
    return defaultValue;
  }

  /// String 필드 정규화 (null을 기본값으로)
  static String normalizeString(
    dynamic value, {
    String defaultValue = '',
  }) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  /// boolean 값 정규화
  static bool normalizeBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) {
      return value != 0;
    }
    return defaultValue;
  }

  /// 상태값을 유효한 값으로 정규화
  static String normalizeStatus(
    dynamic status,
    List<String> validValues, {
    required String defaultValue,
  }) {
    if (status == null) return defaultValue;
    final statusStr = status.toString().toLowerCase();

    // 정확한 일치 찾기
    for (final valid in validValues) {
      if (statusStr == valid.toLowerCase()) {
        return valid;
      }
    }

    // 부분 일치 확인 (예: "ORDERED" vs "ordered")
    for (final valid in validValues) {
      if (valid.toLowerCase().contains(statusStr) ||
          statusStr.contains(valid.toLowerCase())) {
        return valid;
      }
    }

    return defaultValue;
  }

  /// 데이터 맵의 특정 필드 타입 정규화
  /// 여러 필드를 한 번에 정규화할 때 유용
  static Map<String, dynamic> normalizeMap(
    Map<String, dynamic> data, {
    Map<String, dynamic Function(dynamic)>? fieldNormalizers,
  }) {
    final normalized = <String, dynamic>{};

    for (final entry in data.entries) {
      if (fieldNormalizers?.containsKey(entry.key) ?? false) {
        normalized[entry.key] = fieldNormalizers![entry.key]!(entry.value);
      } else {
        normalized[entry.key] = entry.value;
      }
    }

    return normalized;
  }
}
