import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/daily_cards/presentation/providers/providers.dart';

/// Режим темы приложения — персистится в shared_preferences.
/// По умолчанию следует системной настройке; ручной выбор её переопределяет.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Циклит system → light → dark → system и сохраняет выбор.
  Future<void> cycle() async {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    state = next;
    final prefs = ref.read(sharedPreferencesProvider);
    if (next == ThemeMode.system) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, next.name);
    }
  }
}
