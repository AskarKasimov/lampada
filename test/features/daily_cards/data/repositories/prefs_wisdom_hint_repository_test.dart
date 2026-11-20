import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/repositories/prefs_wisdom_hint_repository.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('первое открытие «Мудрости дня» запоминается', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final fresh = await PrefsWisdomHintRepository(prefs).wisdomOpened();
    await PrefsWisdomHintRepository(prefs).markWisdomOpened();
    final again = await PrefsWisdomHintRepository(prefs).wisdomOpened();

    expect((fresh as Success<bool>).value, isFalse);
    expect((again as Success<bool>).value, isTrue);
  });

  test('представленные разделы «Мудрости дня» запоминаются', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = PrefsWisdomHintRepository(prefs);

    final fresh = repository.introducedSections();
    await repository.markSectionIntroduced(CardType.quote);
    await repository.markSectionIntroduced(CardType.advice);
    await repository.markSectionIntroduced(CardType.quote);
    final again = PrefsWisdomHintRepository(prefs).introducedSections();

    expect((fresh as Success<Set<CardType>>).value, isEmpty);
    expect((again as Success<Set<CardType>>).value, {
      CardType.quote,
      CardType.advice,
    });
  });
}
