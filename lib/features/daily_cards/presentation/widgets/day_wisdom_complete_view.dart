import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/format/date_key.dart';
import '../../../../core/format/russian_date.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/day_progress.dart';
import '../providers/providers.dart';
import 'streak_card.dart';

/// Последняя страница «Мудрости дня»: итог дня, серия и выход.
///
/// Только сюда дошедший день засчитывается в «Лампадку». Первое появление
/// за день разыграно как маленькое событие: печать с искрами, затем по
/// очереди текст и серия, в конце лампада загорается на глазах, и уже после
/// неё раскрывается неделя. Повторно итог не показывается: юзер сразу
/// переходит к полной главе, если она есть.
class DayWisdomCompleteView extends ConsumerStatefulWidget {
  const DayWisdomCompleteView({
    required this.date,
    required this.recordsCompletion,
    required this.countsDay,
    required this.onDone,
    this.links = const [],
    super.key,
  });

  final DateTime date;

  /// Записывать ли завершение. Для будущих дат выключено, как и отметки
  /// карточек: предварительное чтение не должно менять прогресс.
  final bool recordsCompletion;

  /// Засчитывает ли экран день в серию. Только тогда серия и показывается:
  /// прошлый день её не меняет, и обещать обратное было бы неправдой.
  final bool countsDay;

  final VoidCallback onDone;

  /// Второстепенные переходы под основной кнопкой, например полная глава.
  /// Первый из них открывается сам при повторном завершении дня.
  final List<({String label, VoidCallback onPressed})> links;

  @override
  ConsumerState<DayWisdomCompleteView> createState() =>
      _DayWisdomCompleteViewState();
}

class _DayWisdomCompleteViewState extends ConsumerState<DayWisdomCompleteView>
    with TickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  /// Кнопки выходят вместе с неделей, в самом конце: до этого момента
  /// внимание держит зажигающаяся лампада.
  late final _actions = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  ScrollPosition? _position;
  var _arrived = false;

  /// Серия до засчитывания дня. Показывается, пока лампада не загорелась.
  DayProgress? _before;
  var _lit = false;
  var _weekShown = false;
  Timer? _weekTimer;

  @override
  void initState() {
    super.initState();
    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed) _lightUp();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position == _position) return;
    _position?.removeListener(_checkArrival);
    _position = position?..addListener(_checkArrival);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkArrival());
  }

  @override
  void dispose() {
    _position?.removeListener(_checkArrival);
    _weekTimer?.cancel();
    _intro.dispose();
    _actions.dispose();
    super.dispose();
  }

  /// Листалка строит страницу, едва та показалась краем при свайпе. День
  /// засчитываем и представление начинаем, только когда страница встала
  /// на место. Она всегда последняя, поэтому это конец прокрутки.
  void _checkArrival() {
    if (_arrived || !mounted) return;
    final position = _position;
    if (position != null &&
        (!position.hasContentDimensions ||
            position.pixels < position.maxScrollExtent - 1)) {
      return;
    }
    _arrived = true;
    _position?.removeListener(_checkArrival);
    _arrive();
  }

  void _arrive() {
    final before = _before = ref.read(dayProgressProvider).value;
    final repeat = before?.isWisdomCompletedOn(widget.date) ?? false;
    if (widget.recordsCompletion) {
      unawaited(_complete(before, repeat: repeat));
    }
    if (repeat && widget.links.isNotEmpty) {
      // Итог уже видели: праздновать второй раз незачем, ведём к главе.
      _openChapter(widget.links.first, auto: true);
      return;
    }
    if (repeat || MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
      _actions.value = 1;
      setState(() {
        _lit = true;
        _weekShown = true;
      });
      return;
    }
    HapticFeedback.lightImpact();
    _intro.forward();
  }

  Future<void> _complete(DayProgress? before, {required bool repeat}) async {
    final analytics = ref.read(analyticsProvider);
    final saved = await ref
        .read(dayProgressProvider.notifier)
        .completeWisdom(date: widget.date, markVisited: widget.countsDay);
    if (!saved || repeat || !mounted) return;
    final after = ref.read(dayProgressProvider).value;
    if (after == null) return;
    analytics.log(
      AnalyticsEvent.wisdomCompleted(
        dayOffset: dayOffset(widget.date),
        countsStreak: widget.countsDay,
        lifetimeDays: after.wisdomCompletedDays.length,
      ),
    );
    final today = DateTime.now();
    if (widget.countsDay &&
        !(before?.isLit(today) ?? false) &&
        after.isLit(today)) {
      analytics.log(
        AnalyticsEvent.lampLit(
          source: LampSource.wisdom,
          streak: after.streakOn(today),
          restarted: (before?.streakOn(today) ?? 0) == 0,
        ),
      );
    }
  }

  void _openChapter(
    ({String label, VoidCallback onPressed}) link, {
    required bool auto,
  }) {
    ref
        .read(analyticsProvider)
        .log(AnalyticsEvent.summaryChapterOpened(auto: auto));
    link.onPressed();
  }

  void _lightUp() {
    if (!mounted || _lit) return;
    setState(() => _lit = true);
    final before = _before;
    final today = DateTime.now();
    final ignites =
        widget.countsDay && before != null && before.streakOn(today) == 0;
    if (widget.countsDay && before != null && !before.isLit(today)) {
      HapticFeedback.mediumImpact();
    }
    // Неделя раскрывается, когда лампада разгорелась; если она уже горела,
    // ждать нечего.
    _weekTimer = Timer(ignites ? streakLampIgnition : Duration.zero, () {
      if (!mounted) return;
      setState(() => _weekShown = true);
      _actions.forward();
    });
  }

  Animation<double> _actionStep(double begin, double end) => CurvedAnimation(
    parent: _actions,
    curve: Interval(begin, end, curve: Curves.easeOutCubic),
  );

  Animation<double> _step(double begin, double end, [Curve? curve]) =>
      CurvedAnimation(
        parent: _intro,
        curve: Interval(begin, end, curve: curve ?? Curves.easeOutCubic),
      );

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final latest = widget.countsDay
        ? ref.watch(dayProgressProvider).value
        : null;
    final progress = _lit ? latest : _before ?? latest;
    return LayoutBuilder(
      // Страница живёт в вертикальной листалке, поэтому вместо прокрутки
      // на маленьком экране или с крупным текстом блок целиком ужимается.
      builder: (context, box) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: box.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Seal(
                  pop: _step(0, 0.45, Curves.elasticOut),
                  burst: _step(0.08, 0.75, Curves.linear),
                  colors: colors,
                ),
                const SizedBox(height: 20),
                _Rise(
                  animation: _step(0.22, 0.55),
                  child: Text(
                    'Слава Богу!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _Rise(
                  animation: _step(0.3, 0.62),
                  child: Text(
                    'Мудрость дня прочитана',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _Rise(
                  animation: _step(0.36, 0.68),
                  child: Text(
                    russianDayMonth(widget.date),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: colors.homeSubtitle),
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 28),
                  _Rise(
                    animation: _step(0.45, 0.8),
                    child: StreakCard(
                      progress: progress,
                      today: DateTime.now(),
                      showWeek: _weekShown,
                      margin: EdgeInsets.zero,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _Rise(
                  animation: _actionStep(0, 0.75),
                  enabled: _weekShown,
                  child: SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      label: 'Готово',
                      color: colors.accent,
                      onPressed: widget.onDone,
                    ),
                  ),
                ),
                for (final link in widget.links) ...[
                  const SizedBox(height: 8),
                  _Rise(
                    animation: _actionStep(0.2, 1),
                    enabled: _weekShown,
                    child: TextButton(
                      onPressed: () => _openChapter(link, auto: false),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              link.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.ink),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            CupertinoIcons.arrow_right,
                            size: 16,
                            color: colors.ink,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Блок проявляется и всплывает на своё место.
class _Rise extends StatelessWidget {
  const _Rise({
    required this.animation,
    required this.child,
    this.enabled = true,
  });

  final Animation<double> animation;
  final Widget child;

  /// Пока блок не показан, он не принимает нажатия: прозрачная кнопка
  /// иначе срабатывала бы от случайного тапа.
  final bool enabled;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !enabled,
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: child,
    ),
  );
}

/// Печать «прочитано»: выпрыгивает с отскоком, от неё расходятся кольцо
/// света и искры, как от затеплённой лампады.
class _Seal extends StatelessWidget {
  const _Seal({required this.pop, required this.burst, required this.colors});

  final Animation<double> pop;
  final Animation<double> burst;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 72,
    child: CustomPaint(
      painter: _SparkBurstPainter(
        progress: burst,
        spark: colors.flameLight,
        glow: colors.accent,
      ),
      child: ScaleTransition(
        scale: pop,
        child: RotationTransition(
          turns: Tween(begin: -0.12, end: 0.0).animate(pop),
          child: Icon(
            CupertinoIcons.checkmark_seal_fill,
            size: 64,
            color: colors.accent,
          ),
        ),
      ),
    ),
  );
}

class _SparkBurstPainter extends CustomPainter {
  _SparkBurstPainter({
    required this.progress,
    required this.spark,
    required this.glow,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color spark;
  final Color glow;

  static const _sparks = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final fade = 1 - t;
    final out = Curves.easeOutCubic.transform(t);

    canvas.drawCircle(
      center,
      lerpDouble(30, 110, out)!,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * fade
        ..color = glow.withValues(alpha: 0.45 * fade),
    );

    final paint = Paint();
    for (var i = 0; i < _sparks; i++) {
      // Разброс детерминированный: каждая вспышка одинаковая, без рандома.
      final angle = i * 2 * math.pi / _sparks + (i.isEven ? 0.13 : -0.09);
      final reach = 78.0 + (i % 3) * 22;
      final distance = lerpDouble(26, reach, out)!;
      final radius = (3.2 - (i % 3) * 0.7) * (1 - t * 0.5);
      final offset =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      paint.color = (i % 4 == 0 ? glow : spark).withValues(alpha: fade);
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SparkBurstPainter oldDelegate) =>
      oldDelegate.spark != spark || oldDelegate.glow != glow;
}
