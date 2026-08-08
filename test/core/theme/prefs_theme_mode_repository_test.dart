import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/theme/prefs_theme_mode_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _FailedWriteStore extends SharedPreferencesStorePlatform {
  @override
  Future<bool> clear() async => true;

  @override
  Future<Map<String, Object>> getAll() async => {};

  @override
  Future<bool> remove(String key) async => false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('без сохранённого выбора возвращает системную тему', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = PrefsThemeModeRepository(
      await SharedPreferences.getInstance(),
    );

    final result = repository.load();

    expect((result as Success<ThemeMode>).value, ThemeMode.system);
  });

  test('возвращает Failure, если prefs отклонил сохранение темы', () async {
    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance = _FailedWriteStore();
    final repository = PrefsThemeModeRepository(
      await SharedPreferences.getInstance(),
    );
    addTearDown(() => SharedPreferences.setMockInitialValues({}));

    expect(await repository.save(ThemeMode.dark), isA<Failure<void>>());
  });
}
