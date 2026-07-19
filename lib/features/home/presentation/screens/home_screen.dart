// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../daily_cards/domain/entities/day_card.dart';
import '../../../daily_cards/domain/entities/day_progress.dart';
import '../../../daily_cards/presentation/providers/providers.dart';
import '../../../daily_cards/presentation/screens/daily_card_screen.dart';
import '../widgets/brand_mark.dart';
import '../widgets/theme_mode_toggle_button.dart';
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
    final cards = ref.watch(todayCardsProvider).requireValue;
    final progress = ref.watch(dayProgressProvider).requireValue;

    return Scaffold(
      body: SafeArea(child: _content(context, ref, cards, progress)),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    List<DayCard> cards,
    DayProgress progress,
  ) {
    final colors = AppColorsExtension.of(context);
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(),
                const SizedBox(height: 5),
                Text(
                  progress.streakDays == 0
                      ? 'Начните сессию'
                      : 'Текущая серия ${progress.streakDays} дней',
                  style: TextStyle(fontSize: 13, color: colors.homeSubtitle),
                ),
                const SizedBox(height: 24),
                Text(
                  'СЕГОДНЯ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.9,
                    color: colors.todayLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TodayStatusChips(cards: cards, readTypes: progress.readTypes),
                const SizedBox(height: 24),
                if (progress.allRead)
                  TextButton(
                    onPressed: () =>
                        ref.read(dayProgressProvider.notifier).resetToday(),
                    style: TextButton.styleFrom(foregroundColor: colors.link),
                    child: Text(
                      'Пройти снова',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: colors.link,
                      ),
                    ),
                  )
                else
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
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
        const Positioned(top: 4, right: 12, child: ThemeModeToggleButton()),
      ],
    );
  }
}
