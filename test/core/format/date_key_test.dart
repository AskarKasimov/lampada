import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';

void main() {
  test('форматирует как yyyy-MM-dd', () {
    expect(dateKey(DateTime(2026, 7, 20)), '2026-07-20');
  });

  test('дополняет нулями месяц и день', () {
    expect(dateKey(DateTime(2026, 1, 2)), '2026-01-02');
  });

  test('время суток на ключ не влияет', () {
    expect(dateKey(DateTime(2026, 7, 20, 23, 59, 59)), '2026-07-20');
  });
}
