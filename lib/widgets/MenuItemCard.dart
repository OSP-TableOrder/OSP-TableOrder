import 'package:flutter/material.dart';

import '../models/MenuItem.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const MenuItemCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 이미지 (플레이스홀더)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200], // 디폴트 배경색
                  child: item.imageUrl != null
                      ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    // TODO: 에러 처리 및 로딩 인디케이터 추가
                  )
                      : Icon(
                    Icons.restaurant, // 기본 포크/나이프 아이콘
                    size: 40,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(width: 16),

              // 2. 메뉴 정보 (이름, 설명, 가격)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '${item.price}원', // TODO: 콤마 포맷팅 (intl 패키지 사용)
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}