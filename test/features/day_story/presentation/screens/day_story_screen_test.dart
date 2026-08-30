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

  testWidgets('показывает заголовок и абзацы рассказа', (tester) async {
    final repo = _FakeRepository(
      const Success(DayStory(paragraphs: ['Абзац первый.', 'Абзац второй.'])),
    );

    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text(_title), findsOneWidget);
    expect(find.text('Абзац первый.'), findsOneWidget);
    expect(find.text('Абзац второй.'), findsOneWidget);
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

    expect(find.byType(SelectableShareArea), findsOneWidget);
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

  testWidgets('«Закрыть» закрывает экран', (tester) async {
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

    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();

    expect(find.byType(DayStoryScreen), findsNothing);
  });
}
