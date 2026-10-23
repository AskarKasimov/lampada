import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

/// Столбик точек прогресса, по которому страницы листаются пальцем: ведёшь
/// вдоль него, и открывается страница под пальцем, на каждой лёгкий
/// щелчок, как у колёсика выбора в iOS. Тап открывает страницу под пальцем.
///
/// Палец переводится в страницу пропорционально высоте столбика, а не по
/// точке под ним: длинный столбик прокручивается к текущей точке, и точки
/// уезжали бы из-под пальца.
class RailScrubber extends StatefulWidget {
  const RailScrubber({
    required this.count,
    required this.currentIndex,
    required this.onSelect,
    required this.child,
    super.key,
  });

  final int count;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final Widget child;

  /// Ширина зоны касания: сами точки 8 pt, пальцу нужно больше.
  static const hitWidth = 32.0;

  @override
  State<RailScrubber> createState() => _RailScrubberState();
}

class _RailScrubberState extends State<RailScrubber> {
  /// Последняя выбранная страница в текущем жесте: родитель перестраивает
  /// столбик не сразу, и без неё один и тот же выбор щёлкал бы повторно.
  int? _last;

  void _select(Offset local) {
    final height = context.size?.height ?? 0;
    if (widget.count <= 0 || height <= 0) return;
    final index = (local.dy / height * widget.count).floor().clamp(
      0,
      widget.count - 1,
    );
    if (index == (_last ?? widget.currentIndex)) return;
    _last = index;
    HapticFeedback.selectionClick();
    widget.onSelect(index);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onVerticalDragStart: (details) {
      _last = null;
      _select(details.localPosition);
    },
    onVerticalDragUpdate: (details) => _select(details.localPosition),
    onVerticalDragEnd: (_) => _last = null,
    onTapUp: (details) {
      _last = null;
      _select(details.localPosition);
      _last = null;
    },
    child: SizedBox(
      width: RailScrubber.hitWidth,
      // По высоте ровно столбик: пропорция считается от него.
      child: Center(heightFactor: 1, child: widget.child),
    ),
  );
}
