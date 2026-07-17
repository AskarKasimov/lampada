import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/providers.dart';
import '../theme/card_type_style.dart';
import '../widgets/card_content.dart';
import '../widgets/progress_dots.dart';
import '../widgets/session_done_view.dart';
import '../widgets/streak_flame.dart';

/// Ядро продукта: ОДНА карточка на весь экран.
/// «Дальше» — добровольно; после первой карточки сессия уже полноценна.
/// На последней карточке — «Готово» и переход к экрану завершения дня.
/// TODO: жесты (свайп), переход между днями.
class DailyCardScreen extends ConsumerStatefulWidget {
  const DailyCardScreen({super.key});

  @override
  ConsumerState<DailyCardScreen> createState() => _DailyCardScreenState();
}

class _DailyCardScreenState extends ConsumerState<DailyCardScreen> {
  int _index = 0;
  bool _done = false;

  void _next(int cardCount) {
    if (_index >= cardCount - 1) {
      setState(() => _done = true);
    } else {
      setState(() => _index++);
    }
  }

  void _restart() => setState(() {
        _index = 0;
        _done = false;
      });

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(todayCardsProvider);
    final streakDays = ref.watch(streakDaysProvider);

    return Scaffold(
      body: SafeArea(
        child: cards.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // TODO: спокойный экран ошибки, не стектрейс.
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            // Защита от RangeError, если данные обновились и список стал короче.
            final index = _index.clamp(0, list.length - 1);
            final isLast = index == list.length - 1;

            return Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 24,
                  child: _StreakBadge(days: streakDays),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween(
                                  begin: const Offset(0, 0.02),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: _done
                                ? SessionDoneView(
                                    key: const ValueKey('done'),
                                    streakDays: streakDays,
                                    onRestart: _restart,
                                  )
                                : CardContent(card: list[index]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ProgressDots(
                        count: list.length,
                        currentIndex: index,
                        accentColors: [
                          for (final card in list) card.type.style.accent,
                        ],
                      ),
                      if (!_done) ...[
                        const SizedBox(height: 20),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 14,
                            ),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => _next(list.length),
                          child: Text(isLast ? 'Готово' : 'Дальше'),
                        ),
                      ] else
                        const SizedBox(height: 20 + 48),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const StreakFlame(),
        const SizedBox(width: 6),
        Text(
          '$days',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
