// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

Widget buildPlatformNetworkImage({
  required String imageUrl,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget? placeholder,
  Widget? errorWidget,
  int? cacheWidth,
  int? cacheHeight,
}) {
  return _WebNetworkImage(
    imageUrl: imageUrl,
    fit: fit,
    width: width,
    height: height,
    placeholder: placeholder,
    errorWidget: errorWidget,
  );
}

class _WebNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const _WebNetworkImage({
    required this.imageUrl,
    required this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<_WebNetworkImage> createState() => _WebNetworkImageState();
}

class _WebNetworkImageState extends State<_WebNetworkImage> {
  static int _imageId = 0;

  late final String _viewType = 'platform-network-image-${_imageId++}';
  late final html.ImageElement _imageElement;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _imageElement = html.ImageElement()
      ..src = widget.imageUrl
      ..style.objectFit = _cssObjectFit(widget.fit)
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.borderRadius = 'inherit'
      ..style.display = 'block';

    _imageElement.onLoad.listen((event) {
      if (mounted) {
        setState(() => _isLoaded = true);
      }
    });

    _imageElement.onError.listen((event) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    });

    // Register an HtmlElementView for CanvasKit CORS-safe rendering.
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int _) => _imageElement,
    );
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = widget.placeholder ??
        const Center(child: CircularProgressIndicator(strokeWidth: 2));
    final errorWidget =
        widget.errorWidget ?? const Icon(Icons.broken_image, color: Colors.grey);

    if (_hasError) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(child: errorWidget),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_isLoaded)
            Positioned.fill(
              child: placeholder,
            ),
          HtmlElementView(viewType: _viewType),
        ],
      ),
    );
  }

  String _cssObjectFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.fill:
        return 'fill';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fitWidth:
        return 'scale-down';
      case BoxFit.fitHeight:
        return 'scale-down';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
    }
  }
}
