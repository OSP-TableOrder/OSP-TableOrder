import 'package:flutter/material.dart';
import 'package:table_order/screens/admin/admin_home_screen.dart';
import 'package:table_order/screens/admin/login.dart';
import 'package:table_order/screens/menu_list_screen.dart';
import 'package:table_order/screens/role_selection_screen.dart';

class AppRoutes {
  static const String roleSelection = '/';
  static const String menuList = '/menulist';
  static const String adminHome = '/adminHome';
  static const String login = '/login';

  static Map<String, WidgetBuilder> routes = {
    roleSelection: (context) => const RoleSelectionScreen(),
    menuList: (context) =>
        const MenuListScreen(storeId: 'default', tableId: 'default'),
    adminHome: (context) => const AdminHomeScreen(),
    login: (context) => const LoginScreen(),
  };
}
