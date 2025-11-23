import 'dart:async';
import 'package:table_order/models/customer/store.dart';

class StoreServerStub {
  final List<Store> fakeStores = [
    Store(
      id: 1,
      name: "kitCAFE",
      isOpened: true,
      headImageUrl:
          "https://oopy.lazyrockets.com/api/v2/notion/image?src=https%3A%2F%2Fprod-files-secure.s3.us-west-2.amazonaws.com%2F22c1d9d0-e308-4831-b48c-f24667512474%2F25f92ab3-9134-4181-95ee-9689c987e5c4%2F%25E1%2584%258C%25E1%2585%25A6%25E1%2584%2586%25E1%2585%25A9%25E1%2586%25A8%25E1%2584%258B%25E1%2585%25B3%25E1%2586%25AF_%25E1%2584%258B%25E1%2585%25B5%25E1%2586%25B8%25E1%2584%2585%25E1%2585%25A7%25E1%2586%25A8%25E1%2584%2592%25E1%2585%25A2%25E1%2584%258C%25E1%2585%25AE%25E1%2584%2589%25E1%2585%25A6%25E1%2584%258B%25E1%2585%25AD_-001_(2).png&blockId=23f8711a-b143-425c-88d3-1148e46e1248",
      description: "따듯한 음료와 디저트로 마음을 사로잡다 - kitCAFE",
      latitude: 36.1455,
      longitude: 128.3932,
    ),
  ];

  Future<List<Store>> fetchStores() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return fakeStores;
  }

  Future<Store?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 400));

    int idx = fakeStores.indexWhere((store) => store.id == id);
    if (idx == -1) return null;

    return fakeStores[idx];
  }
}
