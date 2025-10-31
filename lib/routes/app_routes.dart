import 'package:flutter/material.dart';
import 'package:table_order/screens/home.dart';
import 'package:table_order/screens/store_detail.dart';

class AppRoutes {
  static const String home = '/';
  static const String storeDetail = '/store_detail';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const Home());
      case storeDetail:
        final storeId = settings.arguments as int; // 전달받은 storeId
        return MaterialPageRoute(builder: (_) => StoreDetail(storeId: storeId));
      default:
        return null;
    }
  }
}
