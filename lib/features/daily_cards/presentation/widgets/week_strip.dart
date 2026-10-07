import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/streak_flame.dart';

/// Навигация по неделям с отдельным выбором дня.
class WeekStrip extends StatefulWidget {
  const WeekStrip({
    required this.selected,
    required this.today,
    required this.onSelect,
    this.litDays = const {},
    super.key,
  });

  final DateTime selected;
  final DateTime today;
  final void Function(DateTime day) onSelect;

  /// Ключи `yyyy-MM-dd` дней с активностью. Отмечаются только в месячном
  /// календаре: в полосе недели серию показывает карточка под плитками.
  final Set<String> litDays;

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  late DateTime _weekStart;
  static const _initialPage = 10000;
  late final DateTime _initialWeek;
  late final PageController _controller;

  static DateTime _mondayOf(DateTime day) =>
      DateTime(day.year, day.month, day.day - day.weekday + 1);

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(widget.selected);
    _initialWeek = _weekStart;
    _controller = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (dateKey(oldWidget.selected) != dateKey(widget.selected)) {
      _showWeek(widget.selected);
    }
  }

  DateTime _weekForPage(int page) => DateTime(
    _initialWeek.year,
    _initialWeek.month,
    _initialWeek.day + (page - _initialPage) * 7,
  );

  void _showWeek(DateTime day) {
    _weekStart = _mondayOf(day);
    // Разницу считаем в календарных днях: DST не должен смещать неделю.
    final offset =
        DateTime.utc(_weekStart.year, _weekStart.month, _weekStart.day)
            .difference(
              DateTime.utc(
                _initialWeek.year,
                _initialWeek.month,
                _initialWeek.day,
              ),
            )
            .inDays ~/
        7;
    if (_controller.hasClients) _controller.jumpToPage(_initialPage + offset);
  }

  void _select(DateTime day) {
    setState(() => _showWeek(day));
    widget.onSelect(day);
  }

  Future<void> _openMonth() async {
    final day = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColorsExtension.of(context).background,
      builder: (_) => _MonthCalendar(
        initialMonth: DateTime(
          _weekStart.year,
          _weekStart.month,
          _weekStart.day + 3,
        ),
        selected: widget.selected,
        today: widget.today,
        litDays: widget.litDays,
      ),
    );
    if (day != null && mounted) _select(day);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final middle = DateTime(
      _weekStart.year,
      _weekStart.month,
      _weekStart.day + 3,
    );
    final awayFromToday =
        dateKey(widget.selected) != dateKey(widget.today) ||
        dateKey(_weekStart) != dateKey(_mondayOf(widget.today));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _openMonth,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _monthTitle(middle),
                          style: TextStyle(color: colors.ink),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.chevron_down,
                        size: 12,
                        color: colors.homeIcon,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (awayFromToday)
              TextButton(
                onPressed: () => _select(widget.today),
                child: Text('Сегодня', style: TextStyle(color: colors.accent)),
              ),
          ],
        ),
        SizedBox(
          // PageView требует ограниченной высоты; подпись учитывает масштаб текста.
          height: 49 + MediaQuery.textScalerOf(context).scale(11) * 1.5,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (page) =>
                setState(() => _weekStart = _weekForPage(page)),
            itemBuilder: (context, page) {
              final start = _weekForPage(page);
              return Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: _cell(
                        DateTime(start.year, start.month, start.day + i),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _cell(DateTime day) => _DayCell(
    day: day,
    isSelected: dateKey(day) == dateKey(widget.selected),
    isToday: dateKey(day) == dateKey(widget.today),
    isFuture: dateKey(day).compareTo(dateKey(widget.today)) > 0,
    onTap: () => _select(day),
  );
}

const _months = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

String _monthTitle(DateTime day) => '${_months[day.month - 1]} ${day.year}';

class _MonthCalendar extends StatefulWidget {
  const _MonthCalendar({
    required this.initialMonth,
    required this.selected,
    required this.today,
    required this.litDays,
  });

  final DateTime initialMonth;
  final DateTime selected;
  final DateTime today;
  final Set<String> litDays;

  @override
  State<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<_MonthCalendar> {
  late DateTime _month;
  static const _initialPage = 10000;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.initialMonth.year, widget.initialMonth.month);
    _controller = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) => DateTime(
    widget.initialMonth.year,
    widget.initialMonth.month + page - _initialPage,
  );

  void _moveMonth(int offset) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      (_controller.page ?? _initialPage.toDouble()).round() + offset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Предыдущий месяц',
                    onPressed: () => _moveMonth(-1),
                    icon: Icon(
                      CupertinoIcons.chevron_left,
                      color: colors.homeIcon,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _monthTitle(_month),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: colors.ink),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Следующий месяц',
                    onPressed: () => _moveMonth(1),
                    icon: Icon(
                      CupertinoIcons.chevron_right,
                      color: colors.homeIcon,
                      size: 18,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  for (final day in _DayCell._weekdays)
                    Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.homeSubtitle),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                // Резервируем шесть недель: страницы месяцев не меняют высоту панели.
                height: 6 * 56,
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (page) =>
                      setState(() => _month = _monthForPage(page)),
                  itemBuilder: (context, page) {
                    final month = _monthForPage(page);
                    final leading = month.weekday - 1;
                    final count = DateTime(month.year, month.month + 1, 0).day;
                    return Column(
                      children: [
                        for (var row = 0; row < 6; row++)
                          SizedBox(
                            height: 56,
                            child: Row(
                              children: [
                                for (var col = 0; col < 7; col++)
                                  Expanded(
                                    child: _monthCell(
                                      month,
                                      row * 7 + col - leading + 1,
                                      count,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _monthCell(DateTime month, int number, int count) {
    if (number < 1 || number > count) return const SizedBox(height: 56);
    final day = DateTime(month.year, month.month, number);
    return _DayCell(
      day: day,
      isSelected: dateKey(day) == dateKey(widget.selected),
      isToday: dateKey(day) == dateKey(widget.today),
      isFuture: dateKey(day).compareTo(dateKey(widget.today)) > 0,
      isLit: widget.litDays.contains(dateKey(day)),
      showWeekday: false,
      showLit: true,
      onTap: () => Navigator.of(context).pop(day),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
    this.isLit = false,
    this.showWeekday = true,
    this.showLit = false,
  });

  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;
  final bool showWeekday;
  final bool isLit;

  /// Место под огонёк есть только в месячном календаре.
  final bool showLit;

  static const _weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Semantics(
      selected: isSelected,
      button: true,
      label:
          '${day.day} ${_months[day.month - 1]} ${day.year}, ${_weekdays[day.weekday - 1]}'
          '${isToday ? ', сегодня' : ''}'
          '${showLit && isLit ? ', лампадка затеплена' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showWeekday) ...[
                Text(
                  _weekdays[day.weekday - 1],
                  style: TextStyle(fontSize: 11, color: colors.homeSubtitle),
                ),
                const SizedBox(height: 5),
              ],
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
              if (showLit) ...[
                const SizedBox(height: 4),
                // Место под огонёк держим всегда, иначе строки месяца
                // прыгают по высоте в зависимости от заходов.
                SizedBox(
                  height: 8,
                  child: isLit ? const StreakFlame(size: 6) : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
