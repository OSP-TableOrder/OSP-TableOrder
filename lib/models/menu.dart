class Menu {
  final String menuName;
  final String menuDescription;
  final String? menuImageUrl;
  final int menuPrice;
  final bool menuIsSoldOut;
  final bool menuIsRecommended;

  Menu({
    required this.menuName,
    required this.menuDescription,
    this.menuImageUrl,
    required this.menuPrice,
    required this.menuIsSoldOut,
    required this.menuIsRecommended,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      menuName: json['menuName'] ?? '',
      menuDescription: json['menuDescription'] ?? '',
      menuImageUrl: json['menuImageUrl'],
      menuPrice: json['menuPrice'] ?? 0,
      menuIsSoldOut: json['menuIsSoldOut'] ?? false,
      menuIsRecommended: json['menuIsRecommended'] ?? false,
    );
  }
}
