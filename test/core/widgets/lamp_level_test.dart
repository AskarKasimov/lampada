import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/widgets/lamp_level.dart';

void main() {
  test('0 дней — лампада не горит', () {
    expect(LampLevel.forStreak(0), LampLevel.unlit);
  });

  test('отрицательный стрик тоже не горит, а не падает', () {
    expect(LampLevel.forStreak(-1), LampLevel.unlit);
  });

  test('1–2 дня — затеплилась', () {
    expect(LampLevel.forStreak(1), LampLevel.kindled);
    expect(LampLevel.forStreak(2), LampLevel.kindled);
  });

  test('3–6 дней — горит ровно', () {
    expect(LampLevel.forStreak(3), LampLevel.steady);
    expect(LampLevel.forStreak(6), LampLevel.steady);
  });

  test('7 и больше — наполняет киот', () {
    expect(LampLevel.forStreak(7), LampLevel.full);
    expect(LampLevel.forStreak(365), LampLevel.full);
  });

  test('isLit — false только на unlit', () {
    expect(LampLevel.unlit.isLit, isFalse);
    expect(LampLevel.kindled.isLit, isTrue);
    expect(LampLevel.steady.isLit, isTrue);
    expect(LampLevel.full.isLit, isTrue);
  });
}
