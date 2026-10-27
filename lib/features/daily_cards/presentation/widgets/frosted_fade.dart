import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Мягкий край матового стекла. Ставится вплотную к стеклу и продолжает его:
/// то же размытие и та же подложка, но под градиентной маской, которая
/// плавно сводит их на нет. Так у стекла нет чёткой границы.
///
/// Размытие одной силы, а не полосы с убывающей силой: полосы читались
/// ступеньками. Маска смешивает размытое с резким, и переход выглядит
/// плавным ослаблением размытия.
class FrostedFade extends StatelessWidget {
  const FrostedFade({
    required this.color,
    required this.blur,
    required this.fadesDown,
    super.key,
  });

  /// Подложка стекла у его края.
  final Color color;

  /// Сила размытия самого стекла.
  final double blur;

  /// true: стекло сверху и край растворяется книзу (шапка); false: стекло
  /// снизу и край растворяется кверху (подпись плитки).
  final bool fadesDown;

  static const height = 18.0;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (bounds) => LinearGradient(
      begin: fadesDown ? Alignment.topCenter : Alignment.bottomCenter,
      end: fadesDown ? Alignment.bottomCenter : Alignment.topCenter,
      colors: const [Colors.white, Color(0x00FFFFFF)],
    ).createShader(bounds),
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: ColoredBox(color: color),
        ),
      ),
    ),
  );
}
