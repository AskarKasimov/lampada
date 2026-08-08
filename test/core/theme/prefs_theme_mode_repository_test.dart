import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/theme/prefs_theme_mode_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/shared_preferences_stores.dart';

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

  test('неверный тип темы в prefs отдаёт Failure', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 1});
    final repository = PrefsThemeModeRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.load(), isA<Failure<ThemeMode>>());
  });

  test('возвращает Failure, если prefs отклонил сохранение темы', () async {
    SharedPreferences.resetStatic();
    installSharedPreferencesStore(RejectingWriteStore());
    final repository = PrefsThemeModeRepository(
      await SharedPreferences.getInstance(),
    );
    addTearDown(() => SharedPreferences.setMockInitialValues({}));

    expect(await repository.save(ThemeMode.dark), isA<Failure<void>>());
  });
}
