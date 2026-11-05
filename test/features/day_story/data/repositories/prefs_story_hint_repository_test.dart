import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/day_story/data/repositories/prefs_story_hint_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('подсказка списка святых снимается первым открытием', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final fresh = await PrefsStoryHintRepository(prefs).contentsOpened();
    await PrefsStoryHintRepository(prefs).markContentsOpened();
    final again = await PrefsStoryHintRepository(prefs).contentsOpened();

    expect((fresh as Success<bool>).value, isFalse);
    expect((again as Success<bool>).value, isTrue);
  });
}
