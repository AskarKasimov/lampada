import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/russian_date.dart';

void main() {
  test('склоняет месяц в родительный падеж', () {
    expect(russianDayMonth(DateTime(2026, 7, 19)), '19 июля');
    expect(russianDayMonth(DateTime(2026, 1, 1)), '1 января');
    expect(russianDayMonth(DateTime(2026, 12, 31)), '31 декабря');
  });

  test('май не превращается в «мая мая» и границы месяцев на месте', () {
    expect(russianDayMonth(DateTime(2026, 5, 9)), '9 мая');
    expect(russianDayMonth(DateTime(2026, 2, 29)), '1 марта');
  });
}
