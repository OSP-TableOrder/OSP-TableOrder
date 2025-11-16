import 'package:flutter/material.dart';

import 'package:table_order/screens/home.dart';
import 'package:table_order/screens/store_detail.dart';
import 'package:table_order/screens/cart_screen.dart';
import 'package:table_order/screens/menu_list_screen.dart';

/// 앱 내에서 사용하는 모든 라우트(화면 경로)를 관리하는 클래스.
/// main.dart 의 MaterialApp에서 routes: AppRoutes.routes 로 불러옴.
class AppRoutes {
  // 라우트 이름 정의
  static const String home = '/';
  static const String storeDetail = '/store/detail';
  static const String menuList = '/menu/list';
  static const String cart = '/cart';

  // 라우트 목록 정의
  // route 생성기 (MaterialApp → onGenerateRoute에서 사용)
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const Home());
      
      case storeDetail:
        final storeId = settings.arguments as int; // 전달받은 storeId
        return MaterialPageRoute(
          builder: (_) => StoreDetail(storeId: storeId)
        );

      case menuList:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => MenuListScreen(
            storeId: args['storeId']!,
            tableId: args['tableId']!,
          ),
        );

      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      
      default:
        return _errorRoute();
    }
  }

  // 정의되지 않은 라우트 호출 시 에러 페이지
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(
          child: Text(
            '404 NOT FOUND',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
