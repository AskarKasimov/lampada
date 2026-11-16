import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'progress_dots.dart';
import 'rail_scrubber.dart';

/// Показывает все точки материала; длинная колонка прокручивается к текущей.
/// С [onSelect] по ней можно листать пальцем ([RailScrubber]).
class ReaderProgressRail extends StatefulWidget {
  const ReaderProgressRail({
    required this.count,
    required this.currentIndex,
    required this.accent,
    this.onSelect,
    this.lampDot = false,
    super.key,
  });

  /// Число страниц раздела, без точки итога.
  final int count;
  final int currentIndex;
  final Color accent;

  /// Открывает страницу по индексу точки.
  final ValueChanged<int>? onSelect;

  /// За последней страницей ждёт итог с зажжением лампады: в конце столбика
  /// его точка, как у итога «Мудрости дня». Долистать до неё пальцем нельзя,
  /// до итога доходят чтением.
  final bool lampDot;

  int get _dots => count + (lampDot ? 1 : 0);

  @override
  State<ReaderProgressRail> createState() => ReaderProgressRailState();
}

class ReaderProgressRailState extends State<ReaderProgressRail> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerCurrent());
  }

  @override
  void didUpdateWidget(covariant ReaderProgressRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerCurrent());
    }
  }

  void _centerCurrent() {
    if (!mounted || !_controller.hasClients) return;
    const dotStep = 14.0;
    final position = _controller.position;
    final offset =
        (widget.currentIndex * dotStep -
                position.viewportDimension / 2 +
                dotStep / 2)
            .clamp(0.0, position.maxScrollExtent);
    _controller.animateTo(
      offset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSelect = widget.onSelect;
    final rail = _rail(scrollable: onSelect == null);
    if (onSelect == null) return rail;
    return RailScrubber(
      count: widget._dots,
      currentIndex: widget.currentIndex,
      onSelect: (index) => onSelect(math.min(index, widget.count - 1)),
      child: rail,
    );
  }

  Widget _rail({required bool scrollable}) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      width: 8,
      height: math.min(widget._dots * 14.0, constraints.maxHeight),
      child: SingleChildScrollView(
        controller: _controller,
        // Под пальцем столбик не прокручивают, а листают им страницы.
        physics: scrollable ? null : const NeverScrollableScrollPhysics(),
        child: ProgressDots(
          count: widget._dots,
          currentIndex: widget.currentIndex,
          axis: Axis.vertical,
          accentColors: List.filled(widget._dots, widget.accent),
        ),
      ),
    ),
  );
}
