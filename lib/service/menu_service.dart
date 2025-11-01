import 'package:table_order/models/menu.dart';

class MenuService {
  // TODO: API 호출로 변경
  Future<List<Menu>> fetchMenusByStoreId(int storeId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // 로딩 효과

    // storeId에 따라 더미 데이터 분기 가능
    if (storeId == 1) {
      return [
        Menu(
          menuName: "치킨dd",
          menuDescription: "바삭한 후라이드 치킨",
          menuImageUrl:
              "https://kumoh-talk-bucket.s3.ap-northeast-2.amazonaws.com/KakaoTalk_20250519_021541789.png",
          menuPrice: 15000,
          menuIsSoldOut: false,
          menuIsRecommended: true,
        ),
        Menu(
          menuName: "생맥주",
          menuDescription: "시원한 한 잔!",
          menuImageUrl: null,
          menuPrice: 5000,
          menuIsSoldOut: false,
          menuIsRecommended: false,
        ),
      ];
    }

    return [
      Menu(
        menuName: "모둠안주",
        menuDescription: "안주를 한번에 즐겨요",
        menuImageUrl: null,
        menuPrice: 25000,
        menuIsSoldOut: false,
        menuIsRecommended: false,
      ),
    ];
  }
}
