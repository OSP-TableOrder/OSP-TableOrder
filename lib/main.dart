import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'package:table_order/provider/admin/call_staff_provider.dart';
import 'package:table_order/provider/admin/category_provider.dart';
import 'package:table_order/provider/admin/login_provider.dart';
import 'package:table_order/provider/admin/order_log_provider.dart'
    as admin_order;
import 'package:table_order/provider/admin/product_provider.dart';
import 'package:table_order/provider/admin/store_info_provider.dart';
import 'package:table_order/provider/admin/table_provider.dart';

import 'package:table_order/routes/app_routes.dart';
import 'package:table_order/provider/customer/store_provider.dart';
import 'package:table_order/provider/customer/menu_provider.dart';
import 'package:table_order/provider/customer/cart_provider.dart';
import 'package:table_order/provider/customer/order_provider.dart'
    as customer_order;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TableProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => StoreInfoProvider()),
        ChangeNotifierProvider(
          create: (_) => customer_order.OrderStatusViewModel(),
        ),
        ChangeNotifierProvider(create: (_) => CallStaffProvider()),
        ChangeNotifierProvider(create: (_) => admin_order.OrderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLink();
  }

  Future<void> _initDeepLink() async {
    _appLinks = AppLinks();

    // 앱이 꺼진 상태에서 링크로 실행될 때
    final Uri? initialLink = await _appLinks.getInitialAppLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }

    // 실행 중에 링크가 들어올 때
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    // print("DeepLink : $uri");

    if (uri.host == 'menulist') {
      final storeId = uri.queryParameters['storeId'] ?? 'unknown';
      final tableId = uri.queryParameters['tableId'] ?? 'unknown';

      navigatorKey.currentState?.pushNamed(
        AppRoutes.menuList,
        arguments: {'storeId': storeId, 'tableId': tableId},
      );
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Table Order',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      navigatorKey: navigatorKey,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.roleSelection,
    );
  }
}
