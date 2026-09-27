import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'progress_dots.dart';

/// Показывает все точки материала; длинная колонка прокручивается к текущей.
class ReaderProgressRail extends StatefulWidget {
  const ReaderProgressRail({
    required this.count,
    required this.currentIndex,
    required this.accent,
    super.key,
  });

  final int count;
  final int currentIndex;
  final Color accent;

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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      width: 8,
      height: math.min(widget.count * 14.0, constraints.maxHeight),
      child: SingleChildScrollView(
        controller: _controller,
        child: ProgressDots(
          count: widget.count,
          currentIndex: widget.currentIndex,
          axis: Axis.vertical,
          accentColors: List.filled(widget.count, widget.accent),
        ),
      ),
    ),
  );
}
