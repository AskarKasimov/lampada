import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/theme_mode_provider.dart';
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

  Future<ProviderContainer> build([Map<String, Object> seed = const {}]) async {
    SharedPreferences.setMockInitialValues(seed);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('по умолчанию — системная тема', () async {
    // Раньше провайдер сам читал platformBrightness и отдавал light/dark.
    // Из-за этого приложение не реагировало на смену темы в системе: тёмная
    // появлялась только после перезапуска. Теперь за яркостью следит
    // MaterialApp, а наше дело — не мешать.
    final container = await build();

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('сохранённый выбор перебивает системную', () async {
    final container = await build({'flutter.theme_mode': 'dark'});

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('select() запоминает выбор', () async {
    final container = await build();

    await container.read(themeModeProvider.notifier).select(ThemeMode.light);

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('к системной можно вернуться', () async {
    // Прошлый тумблер был двухпозиционным: один раз переключив, юзер
    // навсегда отвязывался от системы и вернуть связь было нечем.
    final container = await build({'flutter.theme_mode': 'dark'});
    final notifier = container.read(themeModeProvider.notifier);

    await notifier.select(ThemeMode.system);

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('toggle() ходит по кругу система → светлая → тёмная', () async {
    final container = await build();
    final notifier = container.read(themeModeProvider.notifier);

    await notifier.toggle();
    expect(container.read(themeModeProvider), ThemeMode.light);
    await notifier.toggle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
    await notifier.toggle();
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('выбор переживает пересоздание контейнера (те же prefs)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    await first.read(themeModeProvider.notifier).select(ThemeMode.dark);
    first.dispose();

    final second = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(second.dispose);

    expect(second.read(themeModeProvider), ThemeMode.dark);
  });

  test('не меняет тему, если prefs отклонил запись', () async {
    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance = _FailedWriteStore();
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    addTearDown(() => SharedPreferences.setMockInitialValues({}));

    final saved = await container
        .read(themeModeProvider.notifier)
        .select(ThemeMode.dark);

    expect(saved, isFalse);
    expect(container.read(themeModeProvider), ThemeMode.system);
  });
}
