import 'package:flutter/material.dart';

// Admin
import 'package:table_order/screens/admin/admin_home_screen.dart';
import 'package:table_order/screens/admin/login.dart';

// User
import 'package:table_order/screens/home.dart';
import 'package:table_order/screens/role_selection_screen.dart';
import 'package:table_order/screens/store_detail.dart';
import 'package:table_order/screens/menu_list_screen.dart';
import 'package:table_order/screens/cart_screen.dart';

// 앱 전체 라우트 통합 클래스
class AppRoutes {
  // Admin 라우트
  static const String roleSelection = '/';
  static const String adminHome = '/admin/home';
  static const String adminLogin = '/admin/login';

  // 고객용 라우트
  static const String home = '/home';
  static const String storeDetail = '/store/detail';
  static const String menuList = '/menu/list';
  static const String cart = '/cart';

  /// MaterialApp → onGenerateRoute
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Admin
      case roleSelection: // '/'
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());

      case adminHome:
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());

      case adminLogin:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // User
      case home:
        return MaterialPageRoute(builder: (_) => const Home());

      case storeDetail:
        final storeId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => StoreDetail(storeId: storeId));

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

      // Default
      default:
        return _errorRoute();
    }
  }

  // 404 페이지
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(
          child: Text('404 NOT FOUND', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
