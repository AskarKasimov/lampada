import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/screen_tracker.dart';
import '../../../../core/format/russian_date.dart';
import '../../../../core/navigation/bottom_up_modal_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/day_progress.dart';
import '../providers/providers.dart';
import '../widgets/celebration.dart';
import '../widgets/streak_card.dart';

/// Куда юзер ушёл с итога раздела.
enum LampLitExit { continueReading, home }

/// Показывает итог раздела, который только что зажёг сегодняшнюю
/// «Лампадку». [before] — прогресс до зажжения: с него начинается серия на
/// экране, а лампада загорается на глазах.
Future<LampLitExit?> showLampLit(
  BuildContext context, {
  required DayProgress before,
  required String title,
  bool canContinue = true,
  bool canGoHome = true,
}) => Navigator.of(context).push(
  BottomUpModalRoute<LampLitExit>(
    builder: (_) => LampLitScreen(
      before: before,
      title: title,
      canContinue: canContinue,
      canGoHome: canGoHome,
    ),
  ),
);

/// Итог рассказа «Памяти дня», темы курса или главы Библии, зажёгших
/// лампаду. Разыгран как итог «Мудрости дня»: печать с искрами, затем по
/// очереди текст и серия, лампада загорается, после неё раскрывается неделя
/// и выходят кнопки. Показывается только при первом зажжении за день:
/// повторное дочитывание ничего не меняет, и прерывать чтение незачем.
class LampLitScreen extends ConsumerStatefulWidget {
  const LampLitScreen({
    required this.before,
    required this.title,
    this.canContinue = true,
    this.canGoHome = true,
    super.key,
  }) : assert(canContinue || canGoHome, 'С итога должен быть выход');

  final DayProgress before;

  /// Что прочитано: «Память дня прочитана».
  final String title;

  /// Можно ли читать дальше. Рассказ кончается вместе с итогом, а курс и
  /// Библия продолжаются следующей темой или главой.
  final bool canContinue;

  /// Есть ли куда вернуться. Во вкладке «Библия» читалка корневая, и
  /// главная там — другая вкладка, поэтому кнопки нет.
  final bool canGoHome;

  @override
  ConsumerState<LampLitScreen> createState() => _LampLitScreenState();
}

class _LampLitScreenState extends ConsumerState<LampLitScreen>
    with TickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  /// Кнопки выходят вместе с неделей, в самом конце.
  late final _actions = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  var _lit = false;
  var _weekShown = false;
  var _explainFreeze = false;
  Timer? _weekTimer;

  @override
  void initState() {
    super.initState();
    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed) _lightUp();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    unawaited(_checkFreeze());
  }

  Future<void> _checkFreeze() async {
    final explain = await ref.read(explainStreakFreezeProvider)(
      before: widget.before,
      today: DateTime.now(),
    );
    if (explain && mounted) setState(() => _explainFreeze = true);
  }

  @override
  void dispose() {
    _weekTimer?.cancel();
    _intro.dispose();
    _actions.dispose();
    super.dispose();
  }

  void _start() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
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

  void _lightUp() {
    if (!mounted || _lit) return;
    setState(() => _lit = true);
    HapticFeedback.mediumImpact();
    final ignites = widget.before.streakOn(DateTime.now()) == 0;
    // Неделя раскрывается, когда лампада разгорелась.
    _weekTimer = Timer(ignites ? streakLampIgnition : Duration.zero, () {
      if (!mounted) return;
      setState(() => _weekShown = true);
      _actions.forward();
    });
  }

  Animation<double> _step(double begin, double end, [Curve? curve]) =>
      CurvedAnimation(
        parent: _intro,
        curve: Interval(begin, end, curve: curve ?? Curves.easeOutCubic),
      );

  Animation<double> _actionStep(double begin, double end) => CurvedAnimation(
    parent: _actions,
    curve: Interval(begin, end, curve: Curves.easeOutCubic),
  );

  @override
  Widget build(BuildContext context) =>
      AnalyticsScreen(screen: AppScreen.lampLit, child: _buildScreen(context));

  Widget _buildScreen(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final today = DateTime.now();
    final latest = ref.watch(dayProgressProvider).value ?? widget.before;
    final progress = _lit ? latest : widget.before;
    void leave(LampLitExit exit) => Navigator.of(context).pop(exit);
    final actions = [
      if (widget.canContinue)
        (
          label: 'Продолжить чтение',
          onPressed: () => leave(LampLitExit.continueReading),
        ),
      if (widget.canGoHome)
        (
          label: 'Вернуться на главную',
          onPressed: () => leave(LampLitExit.home),
        ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.of(context).horizontal,
          child: LayoutBuilder(
            // Как итог «Мудрости»: на маленьком экране или с крупным текстом
            // блок целиком ужимается, а не прокручивается.
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
                          widget.title,
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
                          russianDayMonth(today),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.homeSubtitle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      CelebrationRise(
                        animation: _step(0.45, 0.8),
                        child: StreakCard(
                          progress: progress,
                          today: today,
                          showWeek: _weekShown,
                          explainFreeze: _explainFreeze,
                          margin: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 32),
                      CelebrationRise(
                        animation: _actionStep(0, 0.75),
                        enabled: _weekShown,
                        child: SizedBox(
                          width: double.infinity,
                          child: AppPrimaryButton(
                            label: actions.first.label,
                            color: colors.accent,
                            onPressed: actions.first.onPressed,
                          ),
                        ),
                      ),
                      for (final action in actions.skip(1)) ...[
                        const SizedBox(height: 8),
                        CelebrationRise(
                          animation: _actionStep(0.2, 1),
                          enabled: _weekShown,
                          child: TextButton(
                            onPressed: action.onPressed,
                            child: Text(
                              action.label,
                              style: TextStyle(color: colors.ink),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
