import 'package:table_order/models/menu.dart';

class MenuService {
  // TODO: API 호출로 변경
  Future<List<Menu>> fetchMenusByStoreId(int storeId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // 로딩 효과

    // storeId에 따라 더미 데이터 분기 가능
    if (storeId == 1) {
      return [
        Menu(
          id: 1,
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
          name: "생맥주",
          description: "시원한 한 잔!",
          imageUrl: null,
          price: 5000,
          isSoldOut: false,
          isRecommended: false,
        ),
      ];
    }

    return [
      Menu(
        id: 3,
        name: "모둠안주",
        description: "안주를 한번에 즐겨요",
        imageUrl: null,
        price: 25000,
        isSoldOut: false,
        isRecommended: false,
      ),
    ];
  }
}
