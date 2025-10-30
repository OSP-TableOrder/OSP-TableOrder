import 'package:flutter/material.dart';
import '../screens/menu_list_screen.dart';

/// 앱 내에서 사용하는 모든 라우트(화면 경로)를 관리하는 클래스.
/// main.dart 의 MaterialApp에서 routes: AppRoutes.routes 로 불러옴.
class AppRoutes {
  // 라우트 이름 정의
  static const String menuList = '/menulist';

  // 라우트 목록 정의
  static Map<String, WidgetBuilder> routes = {
    menuList: (context) => const MenuListScreen(
      storeId: 'default',
      tableId: 'default',
    ),
  };
}
