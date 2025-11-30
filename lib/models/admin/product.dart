class Product {
  final String id;
  final String storeId;
  final String categoryId;

  String name;
  String price;
  int stock;
  bool isSoldOut;
  bool isActive;
  String description;
  String? imageUrl;

  Product({
    required this.id,
    required this.storeId,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.stock,
    required this.isSoldOut,
    required this.isActive,
    required this.description,
    this.imageUrl,
  });
}
