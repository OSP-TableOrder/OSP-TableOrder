class Product {
  final String id;
  final String storeId;
  final String categoryId;

  String name;
  String price;
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
    required this.isSoldOut,
    required this.isActive,
    required this.description,
    this.imageUrl,
  });
}
