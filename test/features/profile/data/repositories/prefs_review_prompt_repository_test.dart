import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/profile/data/repositories/prefs_review_prompt_repository.dart';
import 'package:lampada/features/profile/domain/repositories/review_prompt_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('пустое хранилище: первого входа и запросов нет', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = PrefsReviewPromptRepository(
      await SharedPreferences.getInstance(),
    );

    final state = (await repository.load() as Success<ReviewPromptState>).value;

    expect(state.firstOpenDay, isNull);
    expect(state.lastRequestDay, isNull);
    expect(state.requested, isEmpty);
  });

  test('сохранённое состояние читается обратно', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = PrefsReviewPromptRepository(
      await SharedPreferences.getInstance(),
    );

    await repository.save((
      firstOpenDay: '2026-11-10',
      lastRequestDay: '2026-11-12',
      requested: {ReviewMoment.firstReading, ReviewMoment.laterDayOpen},
    ));
    final state = (await repository.load() as Success<ReviewPromptState>).value;

    expect(state.firstOpenDay, '2026-11-10');
    expect(state.lastRequestDay, '2026-11-12');
    expect(state.requested, {
      ReviewMoment.firstReading,
      ReviewMoment.laterDayOpen,
    });
  });

  test('незнакомые моменты из будущих версий пропускаются', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.review_requested': ['nextDayReturn', 'someday'],
    });
    final repository = PrefsReviewPromptRepository(
      await SharedPreferences.getInstance(),
    );

    final state = (await repository.load() as Success<ReviewPromptState>).value;

    expect(state.requested, {ReviewMoment.nextDayReturn});
  });
}
