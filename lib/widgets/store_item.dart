import 'package:flutter/material.dart';

class StoreItem extends StatelessWidget {
  final String storeName;
  final bool isOpened;
  final String headImageUrl;
  final String description;

  const StoreItem({
    super.key,
    required this.storeName,
    required this.isOpened,
    required this.headImageUrl,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFD7D7D7))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 가게 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              headImageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.store,
                    size: 40,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 10),

          // 가게 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 가게 이름
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // 가게 설명
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9F9F9F),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                // 영업 상태
                Text(
                  isOpened ? "영업중" : "영업 종료",
                  style: TextStyle(
                    fontSize: 12,
                    color: isOpened
                        ? const Color(0xFF6299FE)
                        : const Color(0xFF626161),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
