import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart'; // DeepLink 처리 위한 패키지

import 'dart:async';

import 'provider/store_provider.dart';
import 'provider/menu_provider.dart';
import 'routes/app_routes.dart';
import 'routes/app_routes.dart';
import 'screens/menu_list_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// 전역에서 화면 이동을 처리하기 위해 사용하는 Key
// DeepLink 사용 시, BuildContext 없이 화면 이동 처리 위해 필요

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
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
  late final AppLinks _appLinks; // listener 객체
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLink();
  }

  Future<void> _initDeepLink() async {
    _appLinks = AppLinks();

    // 앱이 꺼진 상태에서 딥링크를 통해 실행된 경우
    final Uri? initialLink = await _appLinks.getInitialAppLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }

    // 앱이 이미 실행 중인 상태에서 딥링크를 받은 경우
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    print('DeepLink : $uri');

    if (uri.host == 'menulist') {
      final storeId = uri.queryParameters['storeId'] ?? 'unknown';
      final tableId = uri.queryParameters['tableId'] ?? 'unknown';

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => MenuListScreen(storeId: storeId, tableId: tableId),
        ),
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
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('홈', style: TextStyle(fontSize: 18))),
    );
  }
}
