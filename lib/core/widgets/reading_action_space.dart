import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Резерв под внешние действия применяется только к тексту. PageView и
/// нетекстовые страницы сохраняют всю высоту и область вертикального свайпа.
class ReadingActionSpace extends InheritedWidget {
  const ReadingActionSpace({
    required this.bottomInset,
    required super.child,
    this.previewExtraInset = 0,
    super.key,
  });

  final double bottomInset;
  final double previewExtraInset;

  static double extraForPreview(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ReadingActionSpace>()
          ?.previewExtraInset ??
      0;

  static double of(BuildContext context, {bool needsFullText = false}) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ReadingActionSpace>();
    return (scope?.bottomInset ?? 0) +
        (needsFullText ? scope?.previewExtraInset ?? 0 : 0);
  }

  @override
  bool updateShouldNotify(ReadingActionSpace oldWidget) =>
      oldWidget.bottomInset != bottomInset ||
      oldWidget.previewExtraInset != previewExtraInset;
}

/// Центр сохраняется в исходной области чтения. Только высокий блок,
/// который задел бы действия снизу, поднимается до безопасной границы.
class ReadingContentPosition extends StatelessWidget {
  const ReadingContentPosition({
    required this.child,
    this.needsFullText = false,
    super.key,
  });

  final Widget child;
  final bool needsFullText;

  @override
  Widget build(BuildContext context) => CustomSingleChildLayout(
    delegate: _ReadingPositionDelegate(
      ReadingActionSpace.of(context, needsFullText: needsFullText),
    ),
    child: child,
  );
}

class _ReadingPositionDelegate extends SingleChildLayoutDelegate {
  const _ReadingPositionDelegate(this.bottomInset);

  final double bottomInset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: constraints.maxWidth,
        maxHeight: (constraints.maxHeight - bottomInset).clamp(
          0.0,
          double.infinity,
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
    (size.width - childSize.width) / 2,
    math
        .min(
          (size.height - childSize.height) / 2,
          size.height - bottomInset - childSize.height,
        )
        .clamp(0.0, double.infinity),
  );

  @override
  bool shouldRelayout(_ReadingPositionDelegate oldDelegate) =>
      oldDelegate.bottomInset != bottomInset;
}
