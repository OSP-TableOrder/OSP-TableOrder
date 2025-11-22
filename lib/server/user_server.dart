import 'dart:async';

import 'package:table_order/models/menu.dart';
import 'package:table_order/models/store.dart';


class Server {
  /// 가게 관련 API

  // Mock API: 모든 가게 가져오기
  Future<List<Store>> getAllStores() async {
    await Future.delayed(const Duration(milliseconds: 500)); // 네트워크 지연 시뮬레이션
    return mockStores;
  }

  // Mock API: 특정 가게 ID로 가게 가져오기
  Future<Store?> getStoreById(int id) async {
    await Future.delayed(const Duration(milliseconds: 300)); // 네트워크 지연 시뮬레이션
    try {
      return mockStores.firstWhere((store) => store.id == id);
    } catch (_) {
      return null; // 가게를 찾지 못한 경우 null 반환
    }
  }

  /// 메뉴 관련 API

  // Mock API: 모든 메뉴 가져오기
  Future<List<Menu>> getAllMenus() async {
    await Future.delayed(const Duration(milliseconds: 500)); // 네트워크 지연 시뮬레이션
    return mockMenus;
  }
  
  // Mock API: 특정 가게의 메뉴 가져오기
  Future<List<Menu>> getMenusByStoreId(int storeId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // 네트워크 지연 시뮬레이션
    return mockMenus.where((menu) => menu.storeId == storeId).toList();
  }

  // Mock API: 메뉴 ID로 특정 메뉴 가져오기
  Future<Menu?> getMenuById(int menuId) async {
    await Future.delayed(const Duration(milliseconds: 300)); // 네트워크 지연 시뮬레이션
    try {
      return mockMenus.firstWhere((menu) => menu.id == menuId);
    } catch (_) {
      return null; // 메뉴를 찾지 못한 경우 null 반환
    }
  }
}


final List<Menu> mockMenus = [
  Menu(
    id: 1,
    storeId: 1,
    name: "치킨dd",
    description: "바삭한 후라이드 치킨",
    imageUrl:
        "https://kumoh-talk-bucket.s3.ap-northeast-2.amazonaws.com/KakaoTalk_20250519_021541789.png",
    price: 15000,
    isSoldOut: false,
    isRecommended: true,
  ),
  Menu(
    id: 2,
    storeId: 1,
    name: "생맥주",
    description: "시원한 한 잔!",
    imageUrl: null,
    price: 5000,
    isSoldOut: false,
    isRecommended: false,
  ),
  Menu(
    id: 3,
    storeId: 2,
    name: "모둠안주",
    description: "안주를 한번에 즐겨요",
    imageUrl: null,
    price: 25000,
    isSoldOut: false,
    isRecommended: true,
  ),
];


final List<Store> mockStores = [
  Store(
    id: 1,
    name: "맥주한잔",
    isOpened: true,
    headImageUrl:
        "https://kumoh-talk-bucket.s3.ap-northeast-2.amazonaws.com/KakaoTalk_20250519_021541789.png",
    description: "시원한 생맥주와 안주!",
    latitude: 36.1455,
    longitude: 128.3932,
  ),
  Store(
    id: 2,
    name: "소주한잔",
    isOpened: false,
    headImageUrl:
        "https://kumoh-talk-bucket.s3.ap-northeast-2.amazonaws.com/KakaoTalk_20250519_021541789.png",
    description: "분위기 좋은 주막입니다.",
    latitude: 36.1449,
    longitude: 128.3924,
  ),
  Store(
    id: 3,
    name: "맥주두잔",
    isOpened: true,
    headImageUrl:
        "https://kumoh-talk-bucket.s3.ap-northeast-2.amazonaws.com/KakaoTalk_20250519_021541789.png",
    description: "시원한 생맥주와 안주!",
    latitude: 36.1455,
    longitude: 128.3932,
  ),
  Store(
    id: 4,
    name: "소주두잔",
    isOpened: false,
    headImageUrl:
        "https://kumoh-talk-bucket.s3.ap-northeast-2.amazonaws.com/KakaoTalk_20250519_021541789.png",
    description: "분위기 좋은 주막입니다.",
    latitude: 36.1449,
    longitude: 128.3924,
  ),
  Store(
    id: 5,
    name: "맥주세잔",
    isOpened: true,
    headImageUrl:
        "https://kumoh-talk-bucket.s3.ap-northeast-2.amazonaws.com/KakaoTalk_20250519_021541789.png",
    description: "시원한 생맥주와 안주!",
    latitude: 36.1455,
    longitude: 128.3932,
  ),
  Store(
    id: 6,
    name: "소주세잔",
    isOpened: false,
    headImageUrl:
        "https://kumoh-talk-bucket.s3.ap-northeast-2.amazonaws.com/KakaoTalk_20250519_021541789.png",
    description: "분위기 좋은 주막입니다.",
    latitude: 36.1449,
    longitude: 128.3924,
  ),
];