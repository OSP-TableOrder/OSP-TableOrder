class Store {
  final String id; // Firestore 자동 생성 ID
  final String name;
  final bool isOpened;
  final String notice;

  Store({
    required this.id,
    required this.name,
    required this.isOpened,
    required this.notice,
  });

  // 서버 JSON 응답을 객체로 변환하는 메서드
  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      isOpened: json['isOpened'] as bool,
      notice: json['notice'] as String,
    );
  }
}
