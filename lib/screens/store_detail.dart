import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:table_order/provider/menu_provider.dart';
import 'package:table_order/widgets/menu_item.dart';
import 'package:table_order/widgets/kakao_map_widget.dart';

class StoreDetail extends StatefulWidget {
  final int storeId;

  const StoreDetail({super.key, this.storeId = 0});

  @override
  State<StoreDetail> createState() => _StoreDetailState();
}

enum StoreTab { menu, location }

class _StoreDetailState extends State<StoreDetail> {
  StoreTab selectedTab = StoreTab.menu;

  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentIndex = 0; // 현재 인덱스 상태 추가

  final List<String> imgSlide = [
    "https://kumoh-talk-bucket.s3.ap-northeast-2.amazonaws.com/KakaoTalk_20250519_021541789.png",
    "https://kumoh-talk-bucket.s3.ap-northeast-2.amazonaws.com/KakaoTalk_20250519_021541789.png",
  ];

  @override
  void initState() {
    super.initState();
    // 가게 id로 메뉴 불러오기
    Future.microtask(
      () => Provider.of<MenuProvider>(
        context,
        listen: false,
      ).loadMenus(widget.storeId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 슬라이드
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CarouselSlider(
                  carouselController: _carouselController,
                  options: CarouselOptions(
                    height: 450,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: true,
                    autoPlay: false,
                    onPageChanged: (index, reason) {
                      setState(() => _currentIndex = index);
                    },
                  ),
                  items: imgSlide.map((url) {
                    return Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  }).toList(),
                ),

                // 하단 점 인디케이터 추가
                Positioned(
                  bottom: 16,
                  child: AnimatedSmoothIndicator(
                    activeIndex: _currentIndex,
                    count: imgSlide.length,
                    effect: const WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 6,
                      activeDotColor: Color(0xFF6299FE),
                      dotColor: Colors.white54,
                    ),
                  ),
                ),
              ],
            ),

            // 가게 기본 정보
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "맥주한잔",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "영업중",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6299FE),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "시원한 생맥주와 안주!",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            _buildTabButtons(),

            IndexedStack(
              index: StoreTab.values.indexOf(selectedTab),
              children: [
                // 메뉴 탭
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: menuProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: menuProvider.menus
                              .map((menu) => MenuItem(menu: menu))
                              .toList(),
                        ),
                ),

                // 위치보기 탭
                SizedBox(
                  height: 400,
                  child: KakaoMapWidget(latitude: 36.1455, longitude: 128.3932),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButtons() {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFECECEC), width: 10),
              bottom: BorderSide(color: Color(0xFFECECEC), width: 1),
            ),
          ),
          child: Row(
            children: [
              _tabButton("메뉴", StoreTab.menu),
              _tabButton("위치보기", StoreTab.location),
            ],
          ),
        ),
        Stack(
          children: [
            Container(height: 2, color: const Color(0xFFECECEC)),
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: selectedTab == StoreTab.menu
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                width: MediaQuery.of(context).size.width / 2,
                height: 2,
                color: const Color(0xFF6299FE),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tabButton(String text, StoreTab tab) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selectedTab == tab
                  ? const Color(0xFF6299FE)
                  : const Color(0xFF343434),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
