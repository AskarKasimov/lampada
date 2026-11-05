import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/repositories/prefs_course_hint_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('подсказка оглавления снимается первым открытием', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final fresh = await PrefsCourseHintRepository(prefs).contentsOpened();
    await PrefsCourseHintRepository(prefs).markContentsOpened();
    final again = await PrefsCourseHintRepository(prefs).contentsOpened();

    expect((fresh as Success<bool>).value, isFalse);
    expect((again as Success<bool>).value, isTrue);
  });
}
