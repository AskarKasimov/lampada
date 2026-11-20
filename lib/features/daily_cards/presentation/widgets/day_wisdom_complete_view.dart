import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/format/date_key.dart';
import '../../../../core/format/russian_date.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/day_progress.dart';
import '../providers/providers.dart';
import 'celebration.dart';
import 'streak_card.dart';

/// Последняя страница «Мудрости дня»: итог дня, серия и выход.
///
/// Из «Мудрости дня» в «Лампадку» засчитывается только дошедший сюда день;
/// остальные разделы зажигают её своим дочитыванием и показывают тот же
/// спектакль в `LampLitScreen`. Первое появление за день разыграно как
/// маленькое событие: печать с искрами, затем по
/// очереди текст и серия, в конце лампада загорается на глазах, и уже после
/// неё раскрывается неделя. При повторном чтении тот же итог показывается
/// сразу и остаётся на экране без анимации.
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

  /// Доступные продолжения чтения, например полные главы.
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
  var _animateStreakChanges = true;
  var _explainFreeze = false;
  Timer? _weekTimer;

  @override
  void initState() {
    super.initState();
    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed) _lightUp();
    });
    final progress = ref.read(dayProgressProvider).value;
    if (progress?.isWisdomCompletedOn(widget.date) ?? false) {
      // Повторный итог должен быть готов до первого кадра: PageView ещё
      // доводит страницу до конца, пока отложенный arrival не вызвал _arrive.
      _before = progress;
      _animateStreakChanges = false;
      _intro.value = 1;
      _actions.value = 1;
      _lit = true;
      _weekShown = true;
    }
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
    if (!repeat && widget.countsDay && before != null) {
      unawaited(_checkFreeze(before));
    }
    if (repeat || MediaQuery.disableAnimationsOf(context)) {
      if (repeat) _animateStreakChanges = false;
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

  Future<void> _checkFreeze(DayProgress before) async {
    final explain = await ref.read(explainStreakFreezeProvider)(
      before: before,
      today: DateTime.now(),
    );
    if (explain && mounted) setState(() => _explainFreeze = true);
  }

  void _openChapter(({String label, VoidCallback onPressed}) link) {
    ref
        .read(analyticsProvider)
        .log(AnalyticsEvent.summaryChapterOpened(auto: false));
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
                CelebrationSeal(
                  pop: _step(0, 0.45, Curves.elasticOut),
                  burst: _step(0.08, 0.75, Curves.linear),
                  colors: colors,
                ),
                const SizedBox(height: 20),
                CelebrationRise(
                  animation: _step(0.22, 0.55),
                  child: Text(
                    'Слава Богу!',
                    textAlign: TextAlign.center,
                    style: AppTheme.headingStyle(context, fontSize: 32),
                  ),
                ),
                const SizedBox(height: 8),
                CelebrationRise(
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
                CelebrationRise(
                  animation: _step(0.36, 0.68),
                  child: Text(
                    russianDayMonth(widget.date),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: colors.homeSubtitle),
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 28),
                  CelebrationRise(
                    animation: _step(0.45, 0.8),
                    child: StreakCard(
                      progress: progress,
                      today: DateTime.now(),
                      showWeek: _weekShown,
                      animateChanges: _animateStreakChanges,
                      explainFreeze: _explainFreeze,
                      margin: EdgeInsets.zero,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (widget.links.isNotEmpty) ...[
                  CelebrationRise(
                    animation: _actionStep(0, 0.75),
                    enabled: _weekShown,
                    child: SizedBox(
                      width: double.infinity,
                      child: AppPrimaryButton(
                        label: widget.links.first.label,
                        color: colors.accent,
                        onPressed: () => _openChapter(widget.links.first),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                CelebrationRise(
                  animation: _actionStep(0.2, 1),
                  enabled: _weekShown,
                  child: TextButton(
                    onPressed: widget.onDone,
                    child: Text(
                      'Вернуться на главную',
                      style: TextStyle(color: colors.ink),
                    ),
                  ),
                ),
                for (final link in widget.links.skip(1)) ...[
                  const SizedBox(height: 8),
                  CelebrationRise(
                    animation: _actionStep(0.2, 1),
                    enabled: _weekShown,
                    child: TextButton(
                      onPressed: () => _openChapter(link),
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
