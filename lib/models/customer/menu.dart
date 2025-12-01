class Menu {
  final String id; // Firestore 자동 생성 ID
  final String storeId; // Firestore 자동 생성 ID
  final String? categoryId; // category → categoryId로 변경
  final String name;
  final String description;
  final String? imageUrl;
  final int price;
  final bool isSoldOut;
  final bool isRecommended;

  Menu({
    required this.id,
    required this.storeId,
    this.categoryId,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.price,
    required this.isSoldOut,
    required this.isRecommended,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    final price = json['price'];
    final priceInt = price is int ? price : (int.tryParse(price as String? ?? '0') ?? 0);

    return Menu(
      id: json['id'] ?? '',
      storeId: json['storeId'] ?? '',
      categoryId: json['categoryId'] ?? json['category'], // 하위 호환성
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      price: priceInt,
      isSoldOut: json['isSoldOut'] ?? false,
      isRecommended: json['isRecommended'] ?? false,
    );
  }
}
