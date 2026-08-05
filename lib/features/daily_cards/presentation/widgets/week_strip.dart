import 'package:flutter/material.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/streak_flame.dart';

/// Полоска недели над карточками дня и единственное место, где видна
/// «Лампадка» (FR-019). Дни листаются жестом по экрану, а здесь остаётся
/// быстрый переход тапом.
///
/// Заменила отдельную вкладку календаря: ради переключения дня открывать
/// целый экран было лишним шагом, а неделя помещается над контентом.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.selected,
    required this.today,
    required this.litDays,
    required this.onSelect,
  });

  final DateTime selected;
  final DateTime today;

  /// Ключи `yyyy-MM-dd` дней с активностью.
  final Set<String> litDays;
  final void Function(DateTime day) onSelect;

  /// Неделя начинается с понедельника, как в русском календаре.
  static DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  @override
  Widget build(BuildContext context) {
    final weekStart = _mondayOf(selected);
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(weekStart.year, weekStart.month, weekStart.day + i),
    ];

    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: _DayCell(
              day: day,
              isSelected: dateKey(day) == dateKey(selected),
              isToday: dateKey(day) == dateKey(today),
              isLit: litDays.contains(dateKey(day)),
              // Будущие дни листать можно, но контента там ещё нет —
              // приглушаем, чтобы не выглядели доступными наравне с прошлым.
              isFuture: day.isAfter(today),
              onTap: () => onSelect(day),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isLit,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool isLit;
  final bool isFuture;
  final VoidCallback onTap;

  static const _weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Semantics(
      selected: isSelected,
      button: true,
      label:
          '${day.day} ${_weekdays[day.weekday - 1]}'
          '${isLit ? ', лампадка затеплена' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _weekdays[day.weekday - 1],
                // 11pt — минимум по HIG.
                style: TextStyle(fontSize: 11, color: colors.homeSubtitle),
              ),
              const SizedBox(height: 5),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colors.accent : null,
                  // Сегодня — кольцо; выбранный день — заливка. Когда это
                  // один и тот же день, заливки достаточно.
                  border: isToday && !isSelected
                      ? Border.all(color: colors.accent, width: 1.5)
                      : null,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected
                        ? colors.background
                        : isFuture
                        ? colors.chipUnreadText
                        : colors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Место под огонёк держим всегда — иначе полоска прыгает
              // по высоте в зависимости от того, в какие дни юзер заходил.
              SizedBox(
                height: 8,
                child: isLit ? const StreakFlame(size: 6) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
