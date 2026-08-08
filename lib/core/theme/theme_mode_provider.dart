import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../result/result.dart';
import '../storage/shared_preferences_provider.dart';
import 'prefs_theme_mode_repository.dart';
import 'theme_mode_repository.dart';
import 'theme_mode_usecases.dart';

final themeModeRepositoryProvider = Provider<ThemeModeRepository>(
  (ref) => PrefsThemeModeRepository(ref.watch(sharedPreferencesProvider)),
);

final loadThemeModeProvider = Provider<LoadThemeMode>(
  (ref) => LoadThemeMode(ref.watch(themeModeRepositoryProvider)),
);

final saveThemeModeProvider = Provider<SaveThemeMode>(
  (ref) => SaveThemeMode(ref.watch(themeModeRepositoryProvider)),
);

/// Режим темы приложения: системная (по умолчанию), светлая, тёмная.
/// Персистится в shared_preferences.
///
/// Раньше системного режима как состояния не было: `build()` один раз читал
/// `platformBrightness` и возвращал light/dark. Приложение из-за этого не
/// реагировало на смену темы в системе — тёмная появлялась только после
/// перезапуска. Теперь по умолчанию отдаём [ThemeMode.system], а следить за
/// яркостью — работа `MaterialApp`, и она делает это без нашего участия.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return switch (ref.watch(loadThemeModeProvider)()) {
      Success(value: final mode) => mode,
      // Если prefs недоступен, системная тема безопаснее произвольной.
      Failure() => ThemeMode.system,
    };
  }

  Future<bool> select(ThemeMode mode) async {
    final result = await ref.read(saveThemeModeProvider)(mode);
    switch (result) {
      case Success<void>():
        state = mode;
        return true;
      case Failure<void>():
        return false;
    }
  }

  /// Цикл «системная → светлая → тёмная → системная». Оставлен для мест,
  /// где переключатель одним тапом (например, будущий виджет-тумблер).
  Future<bool> toggle() => select(switch (state) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  });
}
