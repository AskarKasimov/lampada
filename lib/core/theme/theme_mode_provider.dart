import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/daily_cards/presentation/providers/providers.dart';

/// Режим темы приложения — только светлая/тёмная (без системной как
/// отдельного состояния). Персистится в shared_preferences; пока юзер
/// ничего не выбрал, дефолт берётся из системной яркости платформы.
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
      _ => _systemBrightness() == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
    };
  }

  Brightness _systemBrightness() =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  /// Переключает светлая ↔ тёмная и сохраняет выбор.
  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await ref.read(sharedPreferencesProvider).setString(_key, next.name);
  }
}
