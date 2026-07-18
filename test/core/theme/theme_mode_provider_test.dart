import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/theme_mode_provider.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> build() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('по умолчанию — системный режим', () async {
    final container = await build();
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('cycle() идёт system → light → dark → system', () async {
    final container = await build();
    final notifier = container.read(themeModeProvider.notifier);

    await notifier.cycle();
    expect(container.read(themeModeProvider), ThemeMode.light);

    await notifier.cycle();
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await notifier.cycle();
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('выбор переживает пересоздание контейнера (те же prefs)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    await first.read(themeModeProvider.notifier).cycle();
    expect(first.read(themeModeProvider), ThemeMode.light);
    first.dispose();

    final second = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(second.dispose);
    expect(second.read(themeModeProvider), ThemeMode.light);
  });
}
