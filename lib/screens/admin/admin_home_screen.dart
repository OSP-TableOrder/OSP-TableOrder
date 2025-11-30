import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/provider/admin/table_order_provider.dart';
import 'package:table_order/provider/app_state_provider.dart';
import 'package:table_order/widgets/admin/content_area/category_area.dart';
import 'package:table_order/widgets/admin/content_area/product_area.dart';
import 'package:table_order/widgets/admin/content_area/store_info_area.dart';
import 'package:table_order/widgets/admin/content_area/table_connect_area.dart';
import 'package:table_order/widgets/admin/content_area/table_management_area.dart';
import 'package:table_order/widgets/admin/header/admin_header_bar.dart';
import 'package:table_order/widgets/admin/side_menu_drawer/side_menu_drawer.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  String currentMenu = "default";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = context.read<AppStateProvider>();
      final tableOrderProvider = context.read<TableOrderProvider>();

      if (appState.storeId != null) {
        developer.log(
          'Loading orders for storeId=${appState.storeId}',
          name: 'AdminHomeScreen',
        );
        await tableOrderProvider.loadTables(appState.storeId!);
      }
    });
  }

  void _onMenuSelected(String menu) {
    setState(() => currentMenu = menu);
    Navigator.pop(context); // Drawer 닫기
  }

  Widget _buildContent(String menu) {
    switch (menu) {
      case "가게정보 수정":
        return const StoreInfoArea();
      case "카테고리 수정":
        return const CategoryArea();
      case "상품 수정":
        return const ProductArea();
      case "테이블 연동":
        return const TableConnectArea();
      default:
        return const TableManagementArea(); // 기본 화면
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: SideMenuDrawer(onSelectMenu: _onMenuSelected),
      backgroundColor: const Color(0xffe9eef3),

      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Consumer<TableOrderProvider>(
                builder: (_, __, ___) {
                  return AdminHeaderBar(
                    onMenuPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  );
                },
              ),
            ),

            Expanded(child: _buildContent(currentMenu)),
          ],
        ),
      ),
    );
  }
}
