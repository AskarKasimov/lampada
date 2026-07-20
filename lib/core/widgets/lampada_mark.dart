import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'lamp_level.dart';

/// Лампада: чаша и живой огонёк. Знак приложения, общий для Home, splash,
/// офлайн-вида, экрана загрузки и конца сессии — поэтому лежит в `core/widgets`,
/// а не в фиче.
///
/// [level] по умолчанию [LampLevel.steady]: виджет показывают и там, где стрика
/// на руках нет (загрузка, офлайн), и требовать его было бы враньём про данные.
class LampadaMark extends StatefulWidget {
  const LampadaMark({
    super.key,
    this.size = 18,
    this.level = LampLevel.steady,
    this.heroTag,
  });

  final double size;
  final LampLevel level;

  /// Задаётся только там, где лампада участвует в перелёте между экранами
  /// (splash → Home). Два Hero с одним тегом на одном маршруте роняют
  /// фреймворк, поэтому включается адресно, а не всегда.
  final Object? heroTag;

  @override
  State<LampadaMark> createState() => _LampadaMarkState();
}

class _LampadaMarkState extends State<LampadaMark>
    with SingleTickerProviderStateMixin {
  /// 1.2 с — дрожание язычка. Намеренно не кратно 4-секундному дыханию
  /// свечения (`LampGlow`): кратные периоды сходятся в общий пульс, и сцена
  /// начинает тикать.
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final lit = widget.level.isLit;

    // Огонёк перерисовывается каждый кадр — держим его в своей границе, чтобы
    // не тащить в перерисовку соседей по дереву.
    final painted = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size(widget.size, widget.size * 1.25),
          painter: _LampadaPainter(
            body: lit ? colors.lampBody : colors.lampUnlit,
            flameCore: colors.flameLight,
            flameEdge: colors.accent,
            lit: lit,
            flicker: Curves.easeInOut.transform(_controller.value),
          ),
        ),
      ),
    );

    final tag = widget.heroTag;
    if (tag == null) return painted;
    return Hero(
      tag: tag,
      child: Material(type: MaterialType.transparency, child: painted),
    );
  }
}

class _LampadaPainter extends CustomPainter {
  const _LampadaPainter({
    required this.body,
    required this.flameCore,
    required this.flameEdge,
    required this.lit,
    required this.flicker,
  });

  final Color body;
  final Color flameCore;
  final Color flameEdge;
  final bool lit;

  /// 0..1 — фаза дрожания.
  final double flicker;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rimY = h * 0.55;

    final bowl = Path()
      ..moveTo(w * 0.16, rimY)
      ..quadraticBezierTo(w * 0.5, h * 1.06, w * 0.84, rimY)
      ..close();
    canvas.drawPath(bowl, Paint()..color = body);

    canvas.drawLine(
      Offset(w * 0.12, rimY),
      Offset(w * 0.88, rimY),
      Paint()
        ..color = body
        ..strokeWidth = h * 0.045
        ..strokeCap = StrokeCap.round,
    );

    if (!lit) return;

    final cx = w * 0.5;
    final flameH = h * (0.38 + 0.07 * flicker);
    final tipY = rimY - flameH;
    final flame = Path()
      ..moveTo(cx, tipY)
      ..quadraticBezierTo(cx + w * 0.19, rimY - flameH * 0.32, cx, rimY)
      ..quadraticBezierTo(cx - w * 0.19, rimY - flameH * 0.32, cx, tipY)
      ..close();

    canvas.drawPath(
      flame,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.3),
          colors: [flameCore, flameEdge],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromLTRB(cx - w * 0.2, tipY, cx + w * 0.2, rimY)),
    );
  }

  @override
  bool shouldRepaint(_LampadaPainter old) =>
      old.flicker != flicker ||
      old.lit != lit ||
      old.body != body ||
      old.flameCore != flameCore ||
      old.flameEdge != flameEdge;
}
