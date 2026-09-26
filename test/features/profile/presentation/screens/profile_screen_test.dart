import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/profile/presentation/providers/providers.dart';
import 'package:lampada/features/profile/presentation/screens/profile_screen.dart';
import 'package:lampada/features/profile/presentation/services/profile_actions_service.dart';
import 'package:lampada/features/reminders/data/services/notification_service.dart';
import 'package:lampada/features/reminders/domain/entities/planned_reminder.dart';
import 'package:lampada/features/reminders/presentation/providers/providers.dart';
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

class _NotificationService implements NotificationService {
  @override
  Future<void> init({void Function()? onTap}) async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> isPermitted() async => true;
  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {}
  @override
  Future<void> cancelAll() async {}
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
      notificationServiceProvider.overrideWithValue(_NotificationService()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: ProfileScreen()),
    ),
  );

  testWidgets(
    'напоминания отделены от закладок на 10 px и включают внутренние отступы',
    (tester) async {
      await prefs.setBool('reminders_enabled', true);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      Rect inkFor(String label) => tester.getRect(
        find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
      );
      final reminders = inkFor('Напоминания');
      final toggle = tester.getRect(find.byType(Switch));
      expect(reminders.top - inkFor('Закладки').bottom, 10);
      expect(reminders.bottom, inkFor('Поделиться приложением').top);
      expect(toggle.top - reminders.top, 8);
      expect(reminders.bottom - toggle.bottom, 8);
      await tester.tapAt(Offset(1, reminders.top + 1));
      await tester.pumpAndSettle();
      expect(prefs.getBool('reminders_enabled'), isFalse);
      await tester.tapAt(Offset(1, reminders.bottom - 1));
      await tester.pumpAndSettle();
      expect(prefs.getBool('reminders_enabled'), isTrue);
    },
  );

  testWidgets('напоминания переключаются нажатием у края строки', (
    tester,
  ) async {
    await prefs.setBool('reminders_enabled', true);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    final y = tester.getCenter(find.text('Напоминания')).dy;
    await tester.tapAt(Offset(1, y));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(prefs.getBool('reminders_enabled'), isFalse);
    // Сам переключатель не должен повторно вызывать действие строки.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(prefs.getBool('reminders_enabled'), isTrue);
  });

  testWidgets('ink строк профиля занимает всю ширину экрана', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    for (final label in [
      'Закладки',
      'Напоминания',
      'Поделиться приложением',
      actions.reviewLabel,
      'Политика конфиденциальности',
      'Условия использования',
    ]) {
      final ink = find.ancestor(
        of: find.text(label),
        matching: find.byType(InkWell),
      );
      expect(ink, findsOneWidget, reason: label);
      expect(tester.getRect(ink).left, 0, reason: label);
      expect(tester.getRect(ink).right, 800, reason: label);
    }
    expect(tester.getTopLeft(find.text('Поделиться приложением')).dx, 16);
  });

  testWidgets('заголовок профиля находится в закреплённом AppBar', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.text('ПРОФИЛЬ'), findsNothing);
    final appBar = find.byType(SliverAppBar);
    expect(appBar, findsOneWidget);
    expect(tester.widget<SliverAppBar>(appBar).pinned, isTrue);
    expect(
      find.descendant(of: appBar, matching: find.text('Профиль')),
      findsOneWidget,
    );
  });

  testWidgets('копилка стоит первой, выше настроек темы', (tester) async {
    await tester.pumpWidget(app());
    final bookmarks = find.text('Закладки');
    expect(bookmarks, findsOneWidget);
    expect(
      tester.getBottomLeft(bookmarks).dy,
      lessThan(tester.getTopLeft(find.text('Тема')).dy),
    );
  });

  testWidgets('настройка темы находится после условий использования', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(
      tester.getTopLeft(find.text('Тема')).dy,
      greaterThan(tester.getBottomLeft(find.text('Условия использования')).dy),
    );
  });

  testWidgets('показывает все четыре внешние ссылки', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Поделиться приложением'), findsOneWidget);
    expect(find.text(actions.reviewLabel), findsOneWidget);
    expect(find.text('Политика конфиденциальности'), findsOneWidget);
    expect(find.text('Условия использования'), findsOneWidget);
  });

  testWidgets('«Поделиться» зовёт системный лист «поделиться»', (tester) async {
    await tester.pumpWidget(app());

    await tester.tapAt(
      Offset(1, tester.getCenter(find.text('Поделиться приложением')).dy),
    );
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
