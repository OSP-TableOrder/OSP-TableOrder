import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:table_order/provider/app_state_provider.dart';
import 'package:table_order/provider/admin/category_provider.dart';
import 'package:table_order/provider/admin/login_provider.dart';
import 'package:table_order/provider/admin/order_log_provider.dart' as admin_order;
import 'package:table_order/provider/admin/product_provider.dart';
import 'package:table_order/provider/admin/system_admin_provider.dart';
import 'package:table_order/provider/admin/menu_provider.dart' as admin_menu;
import 'package:table_order/provider/admin/store_provider.dart' as admin_store;
import 'package:table_order/provider/admin/order_provider.dart' as admin_order_provider;
import 'package:table_order/provider/admin/staff_request_provider.dart';

import 'package:table_order/routes/app_routes.dart';
import 'package:table_order/provider/customer/store_provider.dart' as customer_store;
import 'package:table_order/provider/customer/menu_provider.dart' as customer_menu;
import 'package:table_order/provider/customer/cart_provider.dart';
import 'package:table_order/provider/customer/order_provider.dart' as customer_order;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        // App state
        ChangeNotifierProvider(create: (_) => AppStateProvider()),

        // Customer side providers
        ChangeNotifierProvider(create: (_) => customer_store.StoreProvider()),
        ChangeNotifierProvider(create: (_) => customer_menu.MenuProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => customer_order.OrderStatusViewModel()),

        // Admin side providers (legacy - to be kept for backward compatibility)
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SystemAdminProvider()),

        // Admin side providers (new domain-based)
        ChangeNotifierProvider(create: (_) => admin_menu.MenuProvider()),
        ChangeNotifierProvider(create: (_) => admin_store.StoreProvider()),
        ChangeNotifierProvider(create: (_) => admin_order_provider.OrderProvider()),
        ChangeNotifierProvider(create: (_) => StaffRequestProvider()),
        ChangeNotifierProvider(create: (_) => admin_order.OrderLogProvider()),
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
    debugPrint("DeepLink : $uri");

    if (uri.host == 'menulist') {
      final storeId = uri.queryParameters['storeId'] ?? 'unknown';
      final tableId = uri.queryParameters['tableId'] ?? 'unknown';

      // AppState에 storeId와 tableId 저장
      navigatorKey.currentContext?.read<AppStateProvider>().setStoreAndTable(
            storeId: storeId,
            tableId: tableId,
          );

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
