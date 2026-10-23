/// Дата как `yyyy-MM-dd` — машинный формат: сегмент URL Азбуки, ключ кэша
/// карточек, отметка дня в прогрессе.
///
/// Отдельно от `russian_date.dart` намеренно: тот формат читает человек и его
/// можно менять как угодно, а этот попадает в запросы и в `SharedPreferences`,
/// и менять его — ломать совместимость с уже сохранёнными данными.
///
/// Раньше эта функция существовала в трёх копиях (датасорс, репозиторий
/// карточек, репозиторий прогресса). Кэш пишется одной из них, а сверяется
/// другой — разъедься они, и приложение перестало бы узнавать собственный кэш.
String dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Сколько календарных дней [date] отстоит от [today] (по умолчанию от
/// сегодня): 0 сегодня, -1 вчера. UTC-полночь не сдвигается переходом на
/// летнее время, в отличие от разницы локальных дат.
int dayOffset(DateTime date, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final from = DateTime.utc(now.year, now.month, now.day);
  final to = DateTime.utc(date.year, date.month, date.day);
  return to.difference(from).inDays;
}
