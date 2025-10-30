import 'package:flutter/material.dart';

class MenuListScreen extends StatelessWidget {
  final String storeId;   // 주점 id
  final String tableId;   // 테이블 id

  const MenuListScreen({
    super.key,
    required this.storeId,
    required this.tableId,
  });

  // TODO : 실제 메뉴 목록 구현
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('매장 $storeId / 테이블 $tableId')),
      body: Center(
        child: Text(
          '매장 ID: $storeId\n테이블 ID: $tableId',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
