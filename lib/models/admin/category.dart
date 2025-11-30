class Category {
  final String id;
  final String storeId; // Firestore 자동 생성 ID
  String name;
  bool active;
  int order; // 카테고리 표시 순서

  Category({
    required this.id,
    required this.storeId,
    required this.name,
    this.active = true,
    this.order = 0,
  });
}
