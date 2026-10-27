import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/format/russian_date.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../bible/domain/entities/bible_book.dart';
import '../../../bible/presentation/providers/providers.dart';
import '../../domain/entities/day_progress.dart';
import '../providers/providers.dart';
import 'streak_lamp_icon.dart';

/// Доля прочитанных глав для карточки шторки. До первого процента
/// показываем «<1%»: первые главы не должны выглядеть как ноль.
String bibleReadPercentLabel(int read, int total) {
  if (read <= 0 || total <= 0) return '0%';
  final percent = read >= total ? 100 : read * 100 ~/ total;
  return percent == 0 ? '<1%' : '$percent%';
}

/// Открывает шторку «Лампадки» поверх всего шелла. Данные читает сама,
/// чтобы серия и главы обновлялись, пока шторка открыта.
Future<void> showStreakSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      // Шторка открывается из вкладки со своим навигатором; без корневого
      // навигатора её низ ушёл бы под капсулу навбара.
      useRootNavigator: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: AppMotion.modalEnter,
        reverseDuration: AppMotion.modalExit,
      ),
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColorsExtension.of(context).background,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final progress = ref.watch(dayProgressProvider).value;
          if (progress == null) return const SizedBox(height: 120);
          return StreakSheet(
            progress: progress,
            today: DateTime.now(),
            // Главы читаются из prefs почти мгновенно; до ответа и при ошибке
            // показываем ноль, а не пустую карточку.
            bibleChaptersRead:
                ref.watch(bibleChapterStatusesProvider).value?.read.length ?? 0,
            bibleChaptersTotal: bibleChapterTotal,
          );
        },
      ),
    );

/// Содержимое шторки серии: мотивация, текущая и лучшая серия, доля
/// прочитанной Библии, итог года и текущая неделя.
class StreakSheet extends StatelessWidget {
  const StreakSheet({
    required this.progress,
    required this.today,
    required this.bibleChaptersRead,
    required this.bibleChaptersTotal,
    super.key,
  });

  final DayProgress progress;
  final DateTime today;
  final int bibleChaptersRead;
  final int bibleChaptersTotal;

  String get _yearLine {
    final days = progress.litDaysInYear(today.year);
    if (days == 0) return 'В этом году лампада ещё не загоралась';
    return 'В этом году лампада горела $days ${_daysWord(days)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final streak = progress.streakOn(today);
    return SafeArea(
      child: SingleChildScrollView(
        padding:
            AppSpacing.of(context).horizontal +
            const EdgeInsets.only(top: 4, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Лампадка помогает сделать чтение ежедневной привычкой',
              textAlign: TextAlign.center,
              style: AppTheme.headingStyle(context),
            ),
            const SizedBox(height: 24),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Дней подряд',
                      value: '$streak',
                      icon: StreakLampIcon(lit: streak > 0, size: 30),
                      caption: 'Лучшая: ${progress.bestStreakOn(today)}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Библия',
                      value: bibleReadPercentLabel(
                        bibleChaptersRead,
                        bibleChaptersTotal,
                      ),
                      icon: Icon(
                        CupertinoIcons.book_fill,
                        size: 26,
                        color: colors.accent,
                      ),
                      caption: 'Прочитано глав: $bibleChaptersRead',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _yearLine,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: colors.ink),
            ),
            const SizedBox(height: 20),
            _WeekRow(progress: progress, today: today),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.caption,
  });

  final String label;
  final String value;
  final Widget icon;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      container: true,
      label: '$label: $value. $caption',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Та же подложка, что у карточки серии на экране итога.
          color: colors.ink.withValues(alpha: isDark ? 0.07 : 0.045),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 15, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  value,
                  style: AppTheme.headingStyle(
                    context,
                    fontSize: 36,
                  ).copyWith(height: 1.1),
                ),
                icon,
              ],
            ),
            const Spacer(),
            const SizedBox(height: 8),
            Text(
              caption,
              style: TextStyle(fontSize: 14, color: colors.homeSubtitle),
            ),
          ],
        ),
      ),
    );
  }
}

/// Текущая неделя с понедельника: сегодня в акцентном круге, дни, когда
/// лампада горела, отмечены точкой над числом.
class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.progress, required this.today});

  final DayProgress progress;
  final DateTime today;

  static const _short = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _full = [
    'понедельник',
    'вторник',
    'среда',
    'четверг',
    'пятница',
    'суббота',
    'воскресенье',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final todayKey = dateKey(today);
    final monday = DateTime(
      today.year,
      today.month,
      today.day - today.weekday + 1,
    );
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: _day(
              DateTime(monday.year, monday.month, monday.day + i),
              todayKey: todayKey,
              colors: colors,
            ),
          ),
      ],
    );
  }

  Widget _day(
    DateTime day, {
    required String todayKey,
    required AppColorsExtension colors,
  }) {
    final key = dateKey(day);
    final isToday = key == todayKey;
    final isFuture = key.compareTo(todayKey) > 0;
    final lit = progress.isLit(day);
    final textColor = isFuture ? colors.textTertiary : colors.ink;
    return Semantics(
      label:
          '${russianDayMonth(day)}, ${_full[day.weekday - 1]}'
          '${isToday ? ', сегодня' : ''}'
          '${lit ? ', лампада горела' : ''}',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            _short[day.weekday - 1],
            style: TextStyle(fontSize: 15, color: textColor),
          ),
          const SizedBox(height: 6),
          // Место под точку держим всегда, чтобы числа стояли в одну линию.
          SizedBox(
            height: 6,
            child: lit
                ? Container(
                    key: ValueKey('lit-$key'),
                    width: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.accent,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: isToday
                ? BoxDecoration(shape: BoxShape.circle, color: colors.accent)
                : null,
            child: Text(
              '${day.day}',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                color: isToday ? colors.background : textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «1 день», «3 дня», «5 дней».
String _daysWord(int days) {
  final mod100 = days % 100;
  final mod10 = days % 10;
  if (mod100 >= 11 && mod100 <= 14) return 'дней';
  if (mod10 == 1) return 'день';
  if (mod10 >= 2 && mod10 <= 4) return 'дня';
  return 'дней';
}
