class Store {
  final int id;
  final String name;
  final bool isOpened;
  final String headImageUrl;
  final String description;
  final double latitude;
  final double longitude;

  Store({
    required this.id,
    required this.name,
    required this.isOpened,
    required this.headImageUrl,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  // 서버 JSON 응답을 객체로 변환하는 메서드
  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['storeId'] as int,
      name: json['storeName'] as String,
      isOpened: json['isOpened'] as bool,
      headImageUrl: json['headImageUrl'] as String,
      description: json['description'] as String,
      latitude: json['latitude'] ?? 37.5665, // 기본값
      longitude: json['longitude'] ?? 126.9780,
    );
  }
}
