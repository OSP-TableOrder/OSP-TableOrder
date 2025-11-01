import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

class KakaoMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const KakaoMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<KakaoMapWidget> createState() => _KakaoMapWidgetState();
}

class _KakaoMapWidgetState extends State<KakaoMapWidget> {
  late final WebViewController _controller;
  bool _mapLoaded = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            setState(() => _mapLoaded = true);
            // 페이지 로드 완료 후 마커 업데이트 실행
            await _updateMarker();
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://너의GitHub계정.github.io/kakaomap-demo/kakaomap.html'),
      );
  }

  Future<void> _updateMarker() async {
    if (_mapLoaded) {
      await _controller.runJavaScript(
        'updateMarker(${widget.latitude}, ${widget.longitude});',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: WebViewWidget(controller: _controller));
  }
}
