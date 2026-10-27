import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/day_progress.dart';
import 'streak_lamp_icon.dart';

/// «1 день подряд», «3 дня подряд», «5 дней подряд».
String streakDaysLabel(int days) {
  final mod100 = days % 100;
  final mod10 = days % 10;
  if (mod100 >= 11 && mod100 <= 14) return 'дней подряд';
  if (mod10 == 1) return 'день подряд';
  if (mod10 >= 2 && mod10 <= 4) return 'дня подряд';
  return 'дней подряд';
}

/// Серия дней («Лампадка») на экране итога «Мудрости дня»: лампада, число
/// дней и одна фраза. На главной серию показывают шапка и её шторка.
class StreakCard extends StatelessWidget {
  const StreakCard({
    required this.progress,
    required this.today,
    this.showWeek = false,
    this.animateChanges = true,
    this.margin,
    super.key,
  });

  final DayProgress progress;
  final DateTime today;

  /// Последние семь дней с огоньками. Экран итога раскрывает их, когда
  /// лампада загорелась.
  final bool showWeek;

  /// Анимировать смену числа и раскрытие недели.
  final bool animateChanges;

  /// Внешние поля. По умолчанию — боковые поля экрана.
  final EdgeInsetsGeometry? margin;

  String _message(int streak, bool litToday) {
    // Тон как у трекеров привычек: сначала поддержать, потом мягко позвать.
    if (streak == 0) return 'Начните с «Мудрости дня», и лампада загорится.';
    if (!litToday) {
      return 'Загляните в «Мудрость дня», чтобы лампада не погасла.';
    }
    if (streak == 1) {
      return 'Хорошее начало. Загляните завтра, чтобы лампада не погасла.';
    }
    // Отдельной фразы для недели нет: число дней и так видно.
    return 'Вы на верном пути. Загляните завтра, чтобы лампада горела дальше.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = progress.streakOn(today);
    final litToday = progress.isLit(today);
    final label = streakDaysLabel(streak);
    final message = _message(streak, litToday);
    // Смена серии анимируется при первом завершении; Reduce Motion и повторный
    // итог сразу показывают готовые число и неделю.
    final motion = !animateChanges || MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 520);
    final week = showWeek
        ? Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _WeekRow(
              progress: progress,
              today: today,
              animateAppearance: animateChanges,
            ),
          )
        : const SizedBox(width: double.infinity);

    return Padding(
      padding:
          margin ??
          AppSpacing.of(context).horizontal +
              const EdgeInsets.symmetric(vertical: 6),
      child: Semantics(
        container: true,
        label: 'Лампадка: $streak $label. $message',
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: colors.ink.withValues(alpha: isDark ? 0.07 : 0.045),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StreakLamp(lit: streak > 0),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              // Число перекатывается снизу, как счётчик.
                              AnimatedSwitcher(
                                duration: motion,
                                switchInCurve: Curves.easeOutBack,
                                transitionBuilder: (child, animation) =>
                                    ClipRect(
                                      child: SlideTransition(
                                        position: Tween(
                                          begin: Offset(
                                            0,
                                            child.key == ValueKey(streak)
                                                ? 0.9
                                                : -0.9,
                                          ),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      ),
                                    ),
                                child: Text(
                                  '$streak',
                                  key: ValueKey(streak),
                                  style: AppTheme.headingStyle(
                                    context,
                                    fontSize: 28,
                                  ).copyWith(height: 1.1),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: colors.homeSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Неделя может появиться позже карточки: на экране
                // завершения она раскрывается, когда лампада загорелась.
                // AnimatedSize с нулевой длительностью ломает раскладку,
                // поэтому без анимаций неделя просто вставляется.
                if (motion == Duration.zero)
                  week
                else
                  AnimatedSize(
                    duration: motion,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: week,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Сколько разгорается лампада серии. Экран завершения ждёт столько,
/// прежде чем раскрыть неделю.
const streakLampIgnition = Duration(milliseconds: 900);

/// Лампада серии. Загораясь на глазах, она вспыхивает: за ней раскрывается
/// свечение, огонь мерцает и разгорается, сама лампада чуть подпрыгивает.
class _StreakLamp extends StatefulWidget {
  const _StreakLamp({required this.lit});

  final bool lit;

  @override
  State<_StreakLamp> createState() => _StreakLampState();
}

class _StreakLampState extends State<_StreakLamp>
    with SingleTickerProviderStateMixin {
  late final _ignite = AnimationController(
    vsync: this,
    duration: streakLampIgnition,
    value: 1,
  );

  /// Огонь занимается неровно: вспышка, просадка, ровное горение.
  static final _flame = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 18),
    TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.3), weight: 12),
    TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.9), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.9, end: 0.6), weight: 10),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.6,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 45,
    ),
  ]);

  static final _glow = TweenSequence([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 65,
    ),
  ]);

  static final _bounce = TweenSequence([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.18,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.18,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 70,
    ),
  ]);

  @override
  void didUpdateWidget(covariant _StreakLamp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lit &&
        !oldWidget.lit &&
        !MediaQuery.disableAnimationsOf(context)) {
      _ignite.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ignite.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return SizedBox.square(
      dimension: 52,
      child: AnimatedBuilder(
        animation: _ignite,
        builder: (context, _) {
          final t = _ignite.value;
          final on = widget.lit ? _flame.transform(t) : 0.0;
          final glow = widget.lit && _ignite.isAnimating
              ? _glow.transform(t)
              : 0.0;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (glow > 0)
                // Свечение шире самой лампады и выходит за её место.
                Transform.scale(
                  scale: 0.6 + t * 1.4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors.flameLight.withValues(alpha: 0.8 * glow),
                          colors.accent.withValues(alpha: 0.35 * glow),
                          colors.accent.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                    child: const SizedBox.square(dimension: 72),
                  ),
                ),
              Transform.scale(
                // Сама лампада занимает около половины холста иллюстрации,
                // остальное прозрачное поле и свечение.
                scale: 1.7 * (widget.lit ? _bounce.transform(t) : 1),
                child: Stack(
                  children: [
                    if (on < 1)
                      Opacity(
                        opacity: 1 - on,
                        child: Image.asset(streakLampOffAsset),
                      ),
                    if (on > 0)
                      Opacity(
                        opacity: on,
                        child: Image.asset(streakLampOnAsset),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Семь дней, заканчивая сегодняшним. Появляясь, лампадки выходят по очереди
/// слева направо, сегодняшняя последней и с отскоком.
class _WeekRow extends StatefulWidget {
  const _WeekRow({
    required this.progress,
    required this.today,
    required this.animateAppearance,
  });

  final DayProgress progress;
  final DateTime today;
  final bool animateAppearance;

  @override
  State<_WeekRow> createState() => _WeekRowState();
}

class _WeekRowState extends State<_WeekRow>
    with SingleTickerProviderStateMixin {
  late final _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  static const _weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animateAppearance || MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
    } else if (_enter.isDismissed) {
      _enter.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _WeekRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animateAppearance && oldWidget.animateAppearance) {
      _enter.value = 1;
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final today = widget.today;
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: _appear(
              index: i,
              child: _day(
                DateTime(today.year, today.month, today.day - 6 + i),
                isToday: i == 6,
                colors: colors,
              ),
            ),
          ),
      ],
    );
  }

  Widget _appear({required int index, required Widget child}) {
    final start = index * 0.07;
    final isToday = index == 6;
    final animation = CurvedAnimation(
      parent: _enter,
      curve: Interval(
        start,
        isToday ? 1 : start + 0.4,
        curve: isToday ? Curves.elasticOut : Curves.easeOutBack,
      ),
    );
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _enter,
        curve: Interval(start, start + 0.25),
      ),
      child: ScaleTransition(scale: animation, child: child),
    );
  }

  Widget _day(
    DateTime day, {
    required bool isToday,
    required AppColorsExtension colors,
  }) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Сегодняшний день выделен подписью: кольцо вокруг лампадки
      // спорило бы с её свечением.
      Text(
        _weekdays[day.weekday - 1],
        style: TextStyle(
          fontSize: 11,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
          color: isToday ? colors.accent : colors.homeSubtitle,
        ),
      ),
      const SizedBox(height: 4),
      SizedBox.square(
        dimension: 34,
        // Как и у большой лампады, сама лампадка занимает около половины
        // холста иллюстрации.
        child: Transform.scale(
          scale: 1.7,
          child: widget.progress.isLit(day)
              ? Image.asset(streakLampOnAsset)
              // Погашенные дни приглушены, чтобы горящие читались сразу.
              : Opacity(opacity: 0.35, child: Image.asset(streakLampOffAsset)),
        ),
      ),
    ],
  );
}
