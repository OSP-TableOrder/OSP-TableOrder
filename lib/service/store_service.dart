import 'package:table_order/models/store.dart';

class StoreService {
  // 현재는 로컬 더미 데이터지만, 나중에 API 연동 시 이 부분만 바꾸면 됨
  final List<Store> _stores = [
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

  // 전체 가게 목록 가져오기
  List<Store> getAllStores() => _stores;

  // ID로 특정 가게 찾기
  Store? getStoreById(int id) {
    try {
      return _stores.firstWhere((store) => store.id == id);
    } catch (_) {
      return null;
    }
  }
}
