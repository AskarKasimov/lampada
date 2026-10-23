import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../providers/providers.dart';
import '../widgets/reader_preview.dart';

/// Однократное приветствие перед первым контентом: сначала время, которое
/// уходит на ленту, затем читалка как лента, которая питает душу.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({required this.onStart, super.key});

  // Получает контекст этого экрана: контекст сплэша к тапу уже размонтирован.
  final void Function(BuildContext context) onStart;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

const _stepDuration = Duration(milliseconds: 450);

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _controller = PageController();
  int _step = 0;

  bool get _isLast => _step == 1;

  @override
  void initState() {
    super.initState();
    _log(AnalyticsEvent.onboardingStepViewed(OnboardingStep.time));
  }

  void _log(AnalyticsEvent event) => ref.read(analyticsProvider).log(event);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _controller.animateToPage(
      step,
      duration: _stepDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() {
    if (!_isLast) {
      _log(AnalyticsEvent.onboardingStepViewed(OnboardingStep.reader));
      return _goTo(_step + 1);
    }
    _log(AnalyticsEvent.onboardingCompleted());
    ref.read(onboardingRepositoryProvider).markShown();
    widget.onStart(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    // Шаги листаются только кнопкой, как в сторис-онбордингах; системный
    // «назад» на втором шаге возвращает к первому, а не закрывает приложение.
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_step - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding:
                AppSpacing.of(context).horizontal +
                const EdgeInsets.only(top: 24, bottom: 32),
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      const _TimeStep(),
                      _ReaderStep(
                        onVideoFailed: () =>
                            _log(AnalyticsEvent.onboardingVideoFailed()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AppPrimaryButton(
                    label: _isLast ? 'Открыть сегодняшний день' : 'Продолжить',
                    color: colors.accent,
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _headlineStyle(BuildContext context) =>
    AppTheme.quoteStyle(context).copyWith(fontSize: 30, height: 1.3);

TextStyle _subtitleStyle(BuildContext context) => TextStyle(
  fontSize: 16,
  height: 1.45,
  color: AppColorsExtension.of(context).textSecondary,
);

/// Без упрёка: «мы», а не «вы»; вместо вины опыт тех, кому уже помогло.
class _TimeStep extends StatelessWidget {
  const _TimeStep();

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mediascope, 2025: в среднем около 2 ч 45 мин в день в соцмедиа.
            // Формулировка «больше двух часов» держится ниже этой оценки.
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Каждый день мы проводим в соцсетях '),
                  TextSpan(
                    text: 'больше двух часов',
                    style: TextStyle(color: colors.accent),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: _headlineStyle(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Пользователи «Лампады» говорят, что стали меньше скроллить ленту.',
              textAlign: TextAlign.center,
              style: _subtitleStyle(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderStep extends StatelessWidget {
  const _ReaderStep({required this.onVideoFailed});

  final VoidCallback onVideoFailed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Неразрывные пробелы не дают предлогу и «души?» повиснуть строкой.
        Text(
          'Что, если лента станет пищей для\u00A0души?',
          textAlign: TextAlign.center,
          style: _headlineStyle(context),
        ),
        const SizedBox(height: 12),
        Text(
          'Просто листайте, по одной мысли за раз.',
          textAlign: TextAlign.center,
          style: _subtitleStyle(context),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: Center(child: ReaderPreview(onVideoFailed: onVideoFailed)),
        ),
      ],
    );
  }
}
