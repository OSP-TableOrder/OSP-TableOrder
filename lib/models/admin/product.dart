class Product {
  final String id;
  final String categoryId;

  String name;
  String price;
  int stock;
  bool isSoldOut;
  bool isActive;
  String description;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.stock,
    required this.isSoldOut,
    required this.isActive,
    required this.description,
  });
}
