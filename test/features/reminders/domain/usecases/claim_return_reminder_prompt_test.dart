import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/reminders/data/repositories/prefs_return_prompt_repository.dart';
import 'package:lampada/features/reminders/domain/repositories/return_prompt_repository.dart';
import 'package:lampada/features/reminders/domain/usecases/claim_return_reminder_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Broken implements ReturnPromptRepository {
  @override
  Future<Result<ReturnPromptState>> load() async =>
      const Failure(AppFailure('Нет доступа', kind: FailureKind.unknown));

  @override
  Future<Result<void>> save(ReturnPromptState state) async =>
      const Success(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late ClaimReturnReminderPrompt claim;

  setUp(() async {
    now = DateTime(2026, 11, 17, 9);
    SharedPreferences.setMockInitialValues({});
    claim = ClaimReturnReminderPrompt(
      PrefsReturnPromptRepository(await SharedPreferences.getInstance()),
      clock: () => now,
    );
  });

  test('в день первого входа системный запрос не показываем', () async {
    expect(await claim(), isFalse);
    now = now.add(const Duration(hours: 12));
    expect(await claim(), isFalse);
  });

  test('при входе на следующий день спрашиваем один раз', () async {
    await claim();
    now = DateTime(2026, 11, 18, 8);

    expect(await claim(), isTrue);
    expect(await claim(), isFalse);
    now = DateTime(2026, 11, 20, 8);
    expect(await claim(), isFalse);
  });

  test(
    'сбой хранилища: лучше не спросить, чем спрашивать каждый раз',
    () async {
      final broken = ClaimReturnReminderPrompt(_Broken(), clock: () => now);
      expect(await broken(), isFalse);
    },
  );
}
