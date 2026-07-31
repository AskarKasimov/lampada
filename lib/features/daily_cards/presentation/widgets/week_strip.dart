import 'package:flutter/material.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/streak_flame.dart';

/// Порог скорости горизонтального свайпа для перелистывания недели.
const _weekSwipeVelocity = 250.0;

/// Полоска недели над карточками дня: навигация по прошлым и будущим дням
/// (FR-018, FR-021) и единственное место, где видна «Лампадка» (FR-019).
///
/// Заменила отдельную вкладку календаря: ради переключения дня открывать
/// целый экран было лишним шагом, а неделя помещается над контентом.
class WeekStrip extends StatefulWidget {
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

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  /// Понедельник показываемой недели. Своё состояние, а не производное от
  /// [WeekStrip.selected]: листать неделю можно, не меняя выбранный день.
  late DateTime _weekStart = _mondayOf(widget.selected);

  @override
  void didUpdateWidget(WeekStrip old) {
    super.didUpdateWidget(old);
    // Выбор уехал за пределы показанной недели (например, «сегодня»
    // из другого месяца) — подтягиваем неделю за ним.
    if (!_containsSelected) {
      _weekStart = _mondayOf(widget.selected);
    }
  }

  bool get _containsSelected {
    final diff = widget.selected.difference(_weekStart).inDays;
    return diff >= 0 && diff < 7;
  }

  /// Неделя начинается с понедельника, как в русском календаре.
  static DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  void _shiftWeek(int weeks) => setState(
    () => _weekStart = DateTime(
      _weekStart.year,
      _weekStart.month,
      _weekStart.day + weeks * 7,
    ),
  );

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_weekSwipeVelocity) {
      _shiftWeek(1);
    } else if (velocity >= _weekSwipeVelocity) {
      _shiftWeek(-1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(_weekStart.year, _weekStart.month, _weekStart.day + i),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: _handleSwipe,
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: _DayCell(
                day: day,
                isSelected: dateKey(day) == dateKey(widget.selected),
                isToday: dateKey(day) == dateKey(widget.today),
                isLit: widget.litDays.contains(dateKey(day)),
                // Будущие дни листать можно, но контента там ещё нет —
                // приглушаем, чтобы не выглядели доступными наравне с прошлым.
                isFuture: day.isAfter(widget.today),
                onTap: () => widget.onSelect(day),
              ),
            ),
        ],
      ),
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
