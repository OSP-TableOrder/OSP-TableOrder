import 'package:flutter/material.dart';

import 'package:table_order/widgets/customer/measured_size.dart';

class MenuCategoryHeader extends StatelessWidget {
  final String title;
  final GlobalKey? headerKey;
  final ValueChanged<double>? onHeight;

  const MenuCategoryHeader({
    super.key,
    required this.title,
    this.headerKey,
    this.onHeight,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildContent({Key? key}) => Container(
          key: key,
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 10.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        );

    if (onHeight != null) {
      return MeasuredSize(
        key: headerKey,
        onHeight: onHeight!,
        child: buildContent(),
      );
    }

    return buildContent(key: headerKey);
  }
}
