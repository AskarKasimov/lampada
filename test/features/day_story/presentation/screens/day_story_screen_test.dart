import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/widgets/app_share_button.dart';
import 'package:lampada/core/widgets/selectable_share_area.dart';
import 'package:lampada/features/bookmarks/presentation/providers/providers.dart'
    show bookmarksProvider;
import 'package:lampada/features/daily_cards/presentation/widgets/rail_scrubber.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/reader_progress_rail.dart';
import 'package:lampada/features/day_story/domain/entities/day_story.dart';
import 'package:lampada/features/day_story/domain/repositories/day_story_repository.dart';
import 'package:lampada/features/day_story/presentation/providers/providers.dart';
import 'package:lampada/features/day_story/presentation/screens/day_story_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _url = 'https://azbyka.ru/days/sv-ivanov';
const _title = 'Мц. Иулиании Никомидийской';

class _FakeRepository implements DayStoryRepository {
  _FakeRepository(this._result);

  final Result<DayStory> _result;
  int calls = 0;

  @override
  Future<Result<DayStory>> fetch(String url) async {
    calls++;
    return _result;
  }
}

class _PendingRepository implements DayStoryRepository {
  final completer = Completer<Result<DayStory>>();

  @override
  Future<Result<DayStory>> fetch(String url) => completer.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget wrap(DayStoryRepository repository) => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      dayStoryRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const DayStoryScreen(title: _title, storyUrl: _url),
    ),
  );

  Future<void> next(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(0, -600));
    await tester.pumpAndSettle();
  }

  testWidgets('листалка: обложка с заголовком, затем абзацы', (tester) async {
    final repo = _FakeRepository(
      const Success(DayStory(paragraphs: ['Абзац первый.', 'Абзац второй.'])),
    );

    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text(_title), findsOneWidget);
    expect(find.textContaining('Абзац первый.'), findsNothing);
    await next(tester);
    expect(find.text('Абзац первый.\n\nАбзац второй.'), findsOneWidget);
    expect(find.text('— Азбука веры'), findsOneWidget);
  });

  testWidgets('по столбику точек страницы листаются пальцем', (tester) async {
    final repo = _FakeRepository(
      const Success(DayStory(paragraphs: ['Абзац первый.', 'Абзац второй.'])),
    );
    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    final rail = tester.getRect(find.byType(RailScrubber));
    await tester.tapAt(rail.bottomCenter - const Offset(0, 1));
    await tester.pumpAndSettle();

    expect(find.text('Абзац первый.\n\nАбзац второй.'), findsOneWidget);
  });

  testWidgets('длинный рассказ делится на страницы, подпись в конце', (
    tester,
  ) async {
    String paragraph(String word) => List.filled(
      4,
      'Это предложение о святом рассказывает про $word подробно.',
    ).join(' ');
    final paragraphs = [paragraph('детство'), paragraph('подвиг')];
    final repo = _FakeRepository(Success(DayStory(paragraphs: paragraphs)));

    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    final rail = tester.widget<ReaderProgressRail>(
      find.byType(ReaderProgressRail),
    );
    // Обложка и не меньше двух страниц текста.
    expect(rail.count, greaterThanOrEqualTo(3));
    await next(tester);
    expect(find.textContaining('детство'), findsOneWidget);
    expect(find.text('— Азбука веры'), findsNothing);
    for (var page = 2; page < rail.count; page++) {
      await next(tester);
    }
    expect(find.textContaining('подвиг'), findsOneWidget);
    expect(find.text('— Азбука веры'), findsOneWidget);
  });

  testWidgets('показывает кнопку «Поделиться» для рассказа', (tester) async {
    final repo = _FakeRepository(
      const Success(DayStory(paragraphs: ['Абзац первый.'])),
    );

    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    final shareButton = tester.widget<AppShareButton>(
      find.byType(AppShareButton),
    );
    expect(shareButton.text, '$_title\n\nАбзац первый.\n\n— Азбука веры');
  });

  testWidgets('текст рассказа можно выделить и отправить', (tester) async {
    final repo = _FakeRepository(
      const Success(DayStory(paragraphs: ['Абзац первый.'])),
    );

    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.text(_title),
        matching: find.byType(SelectableShareArea),
      ),
      findsWidgets,
    );
  });

  testWidgets('сбой загрузки показывает сообщение и кнопку повтора', (
    tester,
  ) async {
    final repo = _FakeRepository(
      Failure(AppFailure('Ошибка', kind: FailureKind.unknown)),
    );

    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('Рассказ сейчас недоступен'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Закрыть'), findsNothing);
    final closeButton = find.byIcon(CupertinoIcons.xmark);
    expect(closeButton, findsOneWidget);
    expect(tester.getCenter(closeButton).dy, lessThan(80));
    expect(
      tester.getCenter(closeButton).dx,
      greaterThan(tester.getSize(find.byType(Scaffold)).width / 2),
    );
  });

  testWidgets(
    'на обложке крестик находится справа в том же слоте, что при ошибке',
    (tester) async {
      final repo = _FakeRepository(
        const Success(DayStory(paragraphs: ['Абзац первый.'])),
      );

      await tester.pumpWidget(wrap(repo));
      await tester.pumpAndSettle();

      final close = find.byTooltip('Закрыть рассказ');
      expect(close, findsOneWidget);
      final rect = tester.getRect(close);
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(
        rect.left,
        greaterThan(tester.getSize(find.byType(Scaffold)).width / 2),
      );
      expect(rect.top, lessThan(80));
    },
  );

  testWidgets(
    'можно закрыть рассказ во время загрузки и поздний ответ не возвращает его',
    (tester) async {
      final repo = _PendingRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            dayStoryRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) =>
                          const DayStoryScreen(title: _title, storyUrl: _url),
                    ),
                  ),
                  child: const Text('Источник'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Источник'));
      await tester.pumpAndSettle();

      final close = find.byTooltip('Закрыть рассказ');
      expect(close, findsOneWidget);
      expect(
        tester.getCenter(close).dx,
        greaterThan(tester.getSize(find.byType(Scaffold).last).width / 2),
      );
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.text('Источник'), findsOneWidget);
      expect(find.byType(DayStoryScreen), findsNothing);

      repo.completer.complete(
        const Success(DayStory(paragraphs: ['Поздний ответ.'])),
      );
      await tester.pumpAndSettle();
      expect(find.text('Источник'), findsOneWidget);
      expect(find.text('Поздний ответ.'), findsNothing);
    },
  );

  testWidgets('без описания показывает спокойное состояние без повтора', (
    tester,
  ) async {
    final repo = _FakeRepository(const Success(DayStory(paragraphs: [])));

    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('Нет описания сегодня'), findsOneWidget);
    expect(find.text('Рассказ сейчас недоступен'), findsNothing);
    expect(find.text('Повторить'), findsNothing);
    expect(find.byType(AppShareButton), findsNothing);
    expect(find.byIcon(CupertinoIcons.bookmark), findsNothing);
    expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
  });

  testWidgets('сетевой сбой показывает соответствующее сообщение', (
    tester,
  ) async {
    final repo = _FakeRepository(
      Failure(AppFailure('Ошибка', kind: FailureKind.network)),
    );

    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('Нет подключения к интернету'), findsOneWidget);
  });

  testWidgets('кнопка закладки сохраняет весь рассказ, а не только заголовок', (
    tester,
  ) async {
    final repo = _FakeRepository(
      const Success(DayStory(paragraphs: ['Абзац первый.', 'Абзац второй.'])),
    );

    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.bookmark), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.bookmark));
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.bookmark_fill), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DayStoryScreen)),
    );
    final saved = container.read(bookmarksProvider).value!.single;
    expect(saved.text, 'Абзац первый.\n\nАбзац второй.');
    expect(saved.source, _title);
  });

  testWidgets('крестик закрывает экран без текстовой кнопки', (tester) async {
    final repo = _FakeRepository(
      const Success(DayStory(paragraphs: ['Абзац первый.'])),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dayStoryRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const DayStoryScreen(title: _title, storyUrl: _url),
                    ),
                  ),
                  child: const Text('Открыть'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    expect(find.byType(DayStoryScreen), findsOneWidget);

    expect(find.text('Закрыть'), findsNothing);
    expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pumpAndSettle();

    expect(find.byType(DayStoryScreen), findsNothing);
  });

  testWidgets('свайп дальше последней страницы возвращает на главную', (
    tester,
  ) async {
    final repo = _FakeRepository(
      const Success(DayStory(paragraphs: ['Абзац первый.'])),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dayStoryRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const DayStoryScreen(title: _title, storyUrl: _url),
                    ),
                  ),
                  child: const Text('Открыть'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    // Обложка, затем единственная страница текста.
    await next(tester);
    expect(find.text('Абзац первый.'), findsOneWidget);
    expect(find.byType(DayStoryScreen), findsOneWidget);
    final rail = tester.widget<ReaderProgressRail>(
      find.byType(ReaderProgressRail),
    );
    expect(rail.count, 2, reason: 'служебная страница не считается');

    await next(tester);
    expect(find.byType(DayStoryScreen), findsNothing);
    expect(find.text('Открыть'), findsOneWidget);
  });

  group('обложка с иконой', () {
    const icon =
        'https://azbyka.ru/days/storage/images/icons-of-saints/1/a.jpg';

    Finder iconImage() => find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is NetworkImage &&
          (widget.image as NetworkImage).url == icon,
    );

    testWidgets('название наверху, под ним икона дня', (tester) async {
      final repo = _FakeRepository(
        const Success(DayStory(paragraphs: ['Абзац первый.'], iconUrl: icon)),
      );

      await tester.pumpWidget(wrap(repo));
      await tester.pumpAndSettle();

      expect(iconImage(), findsOneWidget);
      final title = find.text(_title).first;
      expect(
        tester.getBottomLeft(title).dy,
        lessThanOrEqualTo(tester.getTopLeft(iconImage()).dy),
      );
    });

    testWidgets('без иконы обложка остаётся с одним названием', (tester) async {
      final repo = _FakeRepository(
        const Success(DayStory(paragraphs: ['Абзац первый.'])),
      );

      await tester.pumpWidget(wrap(repo));
      await tester.pumpAndSettle();

      expect(find.text(_title), findsWidgets);
      expect(find.byType(Image), findsNothing);
    });
  });
}
