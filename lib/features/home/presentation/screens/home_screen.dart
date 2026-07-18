// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../daily_cards/domain/entities/day_card.dart';
import '../../../daily_cards/domain/entities/day_progress.dart';
import '../../../daily_cards/presentation/providers/providers.dart';
import '../../../daily_cards/presentation/screens/daily_card_screen.dart';
import '../../../daily_cards/presentation/widgets/streak_flame.dart';
import '../widgets/today_status_chips.dart';

/// Стартовый экран: серия, статус карточек дня, кнопка входа в сессию.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _start(
    BuildContext context,
    List<DayCard> cards,
    DayProgress progress,
  ) async {
    final firstUnread = progress.firstUnread;
    final startIndex =
        firstUnread == null ? 0 : cards.indexWhere((c) => c.type == firstUnread);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyCardScreen(startIndex: startIndex < 0 ? 0 : startIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(todayCardsProvider);
    final progressAsync = ref.watch(dayProgressProvider);

    return Scaffold(
      body: SafeArea(
        child: (cardsAsync.isLoading || progressAsync.isLoading)
            ? const Center(child: CircularProgressIndicator())
            : _content(
                context,
                ref,
                cardsAsync.requireValue,
                progressAsync.requireValue,
              ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    List<DayCard> cards,
    DayProgress progress,
  ) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StreakFlame(size: 18),
                const SizedBox(height: 24),
                Text(
                  'Лампада',
                  style: AppTheme.quoteStyle.copyWith(fontSize: 36),
                ),
                const SizedBox(height: 5),
                Text(
                  progress.streakDays == 0
                      ? 'Начните сессию'
                      : 'Текущая серия ${progress.streakDays} дней',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.homeSubtitle,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'СЕГОДНЯ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.9,
                    color: AppColors.todayLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TodayStatusChips(cards: cards, readTypes: progress.readTypes),
                const SizedBox(height: 24),
                if (progress.allRead)
                  TextButton(
                    onPressed: () =>
                        ref.read(dayProgressProvider.notifier).resetToday(),
                    style: TextButton.styleFrom(foregroundColor: AppColors.link),
                    child: const Text(
                      'Пройти снова',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.link,
                      ),
                    ),
                  )
                else
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 44,
                        vertical: 14,
                      ),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _start(context, cards, progress),
                    child: Text(progress.readCount == 0 ? 'Начать' : 'Продолжить'),
                  ),
              ],
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 36,
          child: Text(
            'по материалам «Азбуки веры»',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.footer),
          ),
        ),
      ],
    );
  }
}
