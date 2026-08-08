import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/profile/presentation/widgets/theme_mode_toggle_button.dart';
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

  testWidgets('сообщает, если выбор темы не сохранился', (tester) async {
    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance = _FailedWriteStore();
    final prefs = await SharedPreferences.getInstance();
    addTearDown(() => SharedPreferences.setMockInitialValues({}));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ThemeModeSettingTile()),
        ),
      ),
    );

    await tester.tap(find.text('Тёмная'));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось сохранить тему'), findsOneWidget);
  });
}
