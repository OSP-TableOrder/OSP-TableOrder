// lib/widgets/menu_item.dart
import 'package:flutter/material.dart';
import 'package:table_order/models/menu.dart';

class Tag extends StatelessWidget {
  final String content;
  const Tag({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF6299FE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        content,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class MenuItem extends StatefulWidget {
  final Menu menu;
  final VoidCallback? onTap;

  const MenuItem({super.key, required this.menu, this.onTap});

  @override
  State<MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> {
  bool isPopupOpen = false;

  void handleImageClick() {
    if (widget.menu.menuImageUrl != null) {
      setState(() => isPopupOpen = true);
    }
  }

  void closePopup() {
    setState(() => isPopupOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFECECEC))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지
                GestureDetector(
                  onTap: handleImageClick,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                      image: menu.menuImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(menu.menuImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: menu.menuImageUrl == null
                        ? const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (menu.menuIsSoldOut)
                        const Text(
                          "품절",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (menu.menuIsRecommended) const Tag(content: "주막장 추천!"),
                      Text(
                        menu.menuName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        menu.menuDescription,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "${menu.menuPrice}원",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
