import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/repositories/prefs_streak_hint_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('объяснение заморозки запоминается после первого показа', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final fresh = await PrefsStreakHintRepository(prefs).freezeExplained();
    await PrefsStreakHintRepository(prefs).markFreezeExplained();
    final again = await PrefsStreakHintRepository(prefs).freezeExplained();

    expect((fresh as Success<bool>).value, isFalse);
    expect((again as Success<bool>).value, isTrue);
  });
}
