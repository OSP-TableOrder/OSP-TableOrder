class Menu {
  final int id;
  final String name;
  final String description;
  final String? imageUrl;
  final int price;
  final bool isSoldOut;
  final bool isRecommended;

  Menu({
    required this.id,
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
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      price: json['price'] ?? 0,
      isSoldOut: json['isSoldOut'] ?? false,
      isRecommended: json['isRecommended'] ?? false,
    );
  }
}
