import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/format/date_key.dart';
import 'day_card.dart';

part 'day_progress.freezed.dart';

/// Прогресс: прочитанные типы карточек по датам и множество дней, в которые
/// юзер заходил. [readTypes] — срез сегодняшнего дня для сессии и напоминаний.
/// Domain-модель, без JSON.
///
/// Серия («Лампадка») здесь не хранится, а выводится из [visitedDays]. Так
/// требует §«Key Entities» спеки — «производное от посещений». Раньше это был
/// самостоятельный счётчик, который только рос: вернувшись через месяц, юзер
/// видел «14 дней подряд», потому что сбрасывать его было негде.
@freezed
abstract class DayProgress with _$DayProgress {
  const DayProgress._();

  const factory DayProgress({
    required Set<CardType> readTypes,

    /// Даты (yyyy-MM-dd) с активностью. День засчитывается, когда прочитана
    /// хотя бы одна его карточка: по §1 сессия состоялась уже после первой.
    required Set<String> visitedDays,

    /// Типы прочитанного контента по календарным датам.
    @Default(<String, Set<CardType>>{})
    Map<String, Set<CardType>> readTypesByDate,
  }) = _DayProgress;

  bool isRead(CardType type) => readTypes.contains(type);

  bool isReadOn(DateTime date, CardType type) =>
      readTypesByDate[dateKey(date)]?.contains(type) ?? false;

  int get readCount => readTypes.length;

  /// Прочитан ли день целиком. Считается от карточек, которые в этот день
  /// реально пришли, а не от полного списка [CardType]: Азбука отдаёт не все
  /// секции каждый день, и сравнение с полным набором держало бы неполный
  /// день вечно незакрытым — ни «пройти снова», ни огонька.
  bool allReadOf(Iterable<CardType> dayTypes) =>
      dayTypes.isNotEmpty && dayTypes.every(readTypes.contains);

  /// Первый непрочитанный тип, либо null. [dayTypes] обязан идти в порядке
  /// показа — его задаёт [GetTodayCards], а не этот метод.
  CardType? firstUnreadOf(Iterable<CardType> dayTypes) {
    for (final type in dayTypes) {
      if (!readTypes.contains(type)) return type;
    }
    return null;
  }

  bool isLit(DateTime day) => visitedDays.contains(dateKey(day));

  /// Максимальный разрыв, который «Лампадка» переживает: один пропущенный
  /// день разницы в две даты не гасит, два подряд — гасят (FR-020).
  static const _maxGapDays = 2;

  /// Длина серии на [today]: сколько дней с активностью идут подряд, считая
  /// назад и прощая одиночные пропуски. 0 — огонёк притух.
  ///
  /// Считаем именно дни с активностью, а не календарные: пропущенный день
  /// серию продлевает, но сам в неё не входит — иначе «5 дней» набиралось бы
  /// из двух заходов.
  int streakOn(DateTime today) {
    final days = visitedDays.toList()..sort();
    if (days.isEmpty) return 0;

    final todayKey = dateKey(today);
    // Будущие даты (сменилась таймзона, переставили часы) в счёт не берём.
    final past = days.where((d) => d.compareTo(todayKey) <= 0).toList();
    if (past.isEmpty) return 0;

    var previous = DateTime.parse(past.last);
    // Огонёк уже мог притухнуть: с последнего захода прошло больше буфера.
    if (_gap(previous, today) > _maxGapDays) return 0;

    var streak = 1;
    for (final key in past.reversed.skip(1)) {
      final day = DateTime.parse(key);
      if (_gap(day, previous) > _maxGapDays) break;
      streak++;
      previous = day;
    }
    return streak;
  }

  /// Разница в календарных днях. Через UTC — иначе переход на летнее время
  /// даёт 23- и 25-часовые сутки, и `inDays` округляется не туда.
  static int _gap(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}
