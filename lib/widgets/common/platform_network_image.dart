import 'package:flutter/material.dart';

import 'platform_network_image_stub.dart'
    if (dart.library.html) 'platform_network_image_web.dart';

/// Displays a network image while gracefully handling CanvasKit CORS
/// restrictions on the web by delegating to an `HtmlElementView`.
class PlatformNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? cacheWidth;
  final int? cacheHeight;

  const PlatformNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    return buildPlatformNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder,
      errorWidget: errorWidget,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }
}
