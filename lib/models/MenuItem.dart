class MenuItem {
  final String name;
  final String description;
  final int price;
  final String? imageUrl;

  MenuItem({
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
  });
}