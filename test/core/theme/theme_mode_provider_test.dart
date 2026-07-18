import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/theme_mode_provider.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> build() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  tearDown(binding.platformDispatcher.clearPlatformBrightnessTestValue);

  test('по умолчанию — светлая, если платформа светлая', () async {
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    final container = await build();
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('по умолчанию — тёмная, если платформа тёмная', () async {
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    final container = await build();
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('toggle() переключает светлая ↔ тёмная', () async {
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    final container = await build();
    final notifier = container.read(themeModeProvider.notifier);

    await notifier.toggle();
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await notifier.toggle();
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('выбор переживает пересоздание контейнера (те же prefs)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    await first.read(themeModeProvider.notifier).toggle();
    expect(first.read(themeModeProvider), ThemeMode.dark);
    first.dispose();

    final second = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(second.dispose);
    expect(second.read(themeModeProvider), ThemeMode.dark);
  });
}
