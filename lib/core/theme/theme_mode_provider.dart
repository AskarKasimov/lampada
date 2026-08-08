import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/shared_preferences_provider.dart';

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
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    return switch (raw) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      // Ничего не выбрано либо явно выбрана системная — следуем системе.
      _ => ThemeMode.system,
    };
  }

  Future<void> select(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }

  /// Цикл «системная → светлая → тёмная → системная». Оставлен для мест,
  /// где переключатель одним тапом (например, будущий виджет-тумблер).
  Future<void> toggle() => select(switch (state) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  });
}
