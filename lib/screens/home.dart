import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/provider/store_provider.dart';
import 'package:table_order/widgets/store_item.dart';
import 'package:table_order/routes/app_routes.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final stores = storeProvider.stores;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFD7D7D7))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      "https://kumoh-talk-bucket.s3.ap-northeast-2.amazonaws.com/KakaoTalk_20250519_021541789.png",
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "금오공대 축제 주막 정보",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: stores.length,
                itemBuilder: (context, index) {
                  final store = stores[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.storeDetail,
                        arguments: store.id,
                      );
                    },
                    child: StoreItem(
                      storeName: store.name,
                      isOpened: store.isOpened,
                      headImageUrl: store.headImageUrl,
                      description: store.description,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
