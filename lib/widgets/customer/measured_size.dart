import 'package:flutter/widgets.dart';

/// Measures its child's height after layout and reports it via [onHeight].
///
/// This widget keeps reporting minimum changes (>= 0.5px) to avoid noisy updates.
class MeasuredSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<double> onHeight;

  const MeasuredSize({
    super.key,
    required this.child,
    required this.onHeight,
  });

  @override
  State<MeasuredSize> createState() => _MeasuredSizeState();
}

class _MeasuredSizeState extends State<MeasuredSize> {
  double? _lastReportedHeight;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox) return;
      final newHeight = renderObject.size.height;
      if (_lastReportedHeight == null ||
          (_lastReportedHeight! - newHeight).abs() > 0.5) {
        _lastReportedHeight = newHeight;
        widget.onHeight(newHeight);
      }
    });

    return widget.child;
  }
}
