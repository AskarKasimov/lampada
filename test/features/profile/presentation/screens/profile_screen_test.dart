import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/profile/presentation/providers/providers.dart';
import 'package:lampada/features/profile/presentation/screens/profile_screen.dart';
import 'package:lampada/features/profile/presentation/services/profile_actions_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Настоящий сервис дёргает url_launcher/share_plus/in_app_review — их
/// платформенных каналов в `flutter test` нет. Фейк только записывает вызовы.
class _FakeProfileActionsService implements ProfileActionsService {
  final openedUrls = <String>[];
  var shareCalls = 0;
  var reviewCalls = 0;
  var reviewResult = true;

  @override
  var reviewLabel = 'Оставить отзыв в App Store';

  @override
  Future<void> openUrl(String url) async => openedUrls.add(url);

  @override
  Future<void> shareApp() async => shareCalls++;

  @override
  Future<bool> requestReview() async {
    reviewCalls++;
    return reviewResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late _FakeProfileActionsService actions;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    actions = _FakeProfileActionsService();
  });

  Widget app() => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      profileActionsServiceProvider.overrideWithValue(actions),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: ProfileScreen()),
    ),
  );

  testWidgets('показывает все четыре внешние ссылки', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Поделиться приложением'), findsOneWidget);
    expect(find.text(actions.reviewLabel), findsOneWidget);
    expect(find.text('Политика конфиденциальности'), findsOneWidget);
    expect(find.text('Условия использования'), findsOneWidget);
  });

  testWidgets('«Поделиться» зовёт системный лист «поделиться»', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('Поделиться приложением'));
    await tester.pump();

    expect(actions.shareCalls, 1);
  });

  testWidgets('«Оставить отзыв» зовёт запрос StoreKit', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text(actions.reviewLabel));
    await tester.pump();

    expect(actions.reviewCalls, 1);
  });

  testWidgets('ошибка формы отзыва показывается пользователю', (tester) async {
    actions.reviewResult = false;
    await tester.pumpWidget(app());

    await tester.tap(find.text(actions.reviewLabel));
    await tester.pump();

    expect(find.text('Не удалось открыть форму отзыва'), findsOneWidget);
  });

  testWidgets('политика конфиденциальности открывает ссылку разработчика', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('Политика конфиденциальности'));
    await tester.pump();

    expect(
      actions.openedUrls.single,
      'https://sites.google.com/view/lampada-privacy-policy/'
      '%D0%B3%D0%BB%D0%B0%D0%B2%D0%BD%D0%B0%D1%8F-'
      '%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%86%D0%B0',
    );
  });

  testWidgets('условия использования открывают ссылку разработчика', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('Условия использования'));
    await tester.pump();

    expect(
      actions.openedUrls.single,
      'https://sites.google.com/view/lampada-terms-of-use/',
    );
  });
}
