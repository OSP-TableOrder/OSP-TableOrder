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
  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: fit,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return placeholder ??
          const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
    },
    errorBuilder: (context, error, stackTrace) {
      return errorWidget ??
          const Icon(
            Icons.broken_image,
            color: Colors.grey,
          );
    },
  );
}
