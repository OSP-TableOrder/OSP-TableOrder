class Menu {
  final int id;
  final int storeId;
  final String? category;
  final String name;
  final String description;
  final String? imageUrl;
  final int price;
  final bool isSoldOut;
  final bool isRecommended;

  Menu({
    required this.id,
    required this.storeId,
    this.category,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.price,
    required this.isSoldOut,
    required this.isRecommended,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'] ?? 0,
      storeId: json['storeId'] ?? 0,
      category: json['category'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      price: json['price'] ?? 0,
      isSoldOut: json['isSoldOut'] ?? false,
      isRecommended: json['isRecommended'] ?? false,
    );
  }
}
