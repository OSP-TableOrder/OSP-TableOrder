import 'package:flutter/material.dart';
import 'package:table_order/screens/admin/admin_home_screen.dart';
import 'package:table_order/screens/admin/login.dart';
import 'package:table_order/screens/menu_list_screen.dart';
import 'package:table_order/screens/role_selection_screen.dart';

/// 앱 내 라우트를 관리하는 클래스.
/// main.dart에서 routes: AppRoutes.routes 로 사용.
class AppRoutes {
  // 라우트 이름 정의
  static const String roleSelection = '/';
  static const String menuList = '/menulist';
  static const String adminHome = '/adminHome';
  static const String login = '/login';

  // 라우트 목록 정의
  static Map<String, WidgetBuilder> routes = {
    roleSelection: (context) => const RoleSelectionScreen(),
    menuList: (context) =>
        const MenuListScreen(storeId: 'default', tableId: 'default'),
    adminHome: (context) => const AdminHomeScreen(),
    login: (context) => const LoginScreen(),
  };

  // 동적 라우트 처리 (필요할 때만 사용)
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());

      case menuList:
        return MaterialPageRoute(
          builder: (_) =>
              const MenuListScreen(storeId: 'default', tableId: 'default'),
        );

      case adminHome:
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      default:
        return null;
    }
  }
}
