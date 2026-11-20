import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/features/bible/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_memory.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_preloader.dart';
import 'package:lampada/features/day_story/domain/entities/day_story.dart';
import 'package:lampada/features/day_story/presentation/providers/providers.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:lampada/features/reading/presentation/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Cards implements DayCardsRepository {
  _Cards({this.pictureUrl});

  final String? pictureUrl;

  @override
  Future<Result<TodayCards>> getCardsFor(
    DateTime date, {
    bool forceRefresh = false,
  }) async => Success(
    TodayCards(
      pictureUrl: pictureUrl,
      cards: const [
        DayCard(
          id: 'reading',
          type: CardType.reading,
          body: 'Ин.10:1–9',
          source: 'Азбука веры',
          reference: 'Jn.10:1-9',
        ),
      ],
      memories: const [DayMemory(title: 'Святой', storyUrl: 'story-1')],
    ),
  );
}

void main() {
  testWidgets('с запуска грузит Евангелие, рассказ и стих дня без главной', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final readings = <String>[];
    final stories = <String>[];
    final verses = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dayCardsRepositoryProvider.overrideWithValue(_Cards()),
          dailyReadingProvider.overrideWith((ref, reference) async {
            readings.add(reference);
            return const DailyReading(label: 'Ин.10:1–9', verses: []);
          }),
          dayStoryProvider.overrideWith((ref, url) async {
            stories.add(url);
            return const DayStory(paragraphs: ['Житие']);
          }),
          verseOfDayProvider.overrideWith((ref, key) async {
            verses.add(key);
            throw const AppFailure('Нет сети', kind: FailureKind.network);
          }),
        ],
        child: const MaterialApp(home: DayPreloader(child: SizedBox())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(readings, ['Jn.10:1-9']);
    expect(stories, ['story-1']);
    expect(verses, [dateKey(DateTime.now())]);
  });

  testWidgets('недоступная «Картина дня» не роняет предзагрузку', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dayCardsRepositoryProvider.overrideWithValue(
            _Cards(pictureUrl: 'https://example.invalid/picture.jpg'),
          ),
          dailyReadingProvider.overrideWith(
            (ref, reference) async =>
                const DailyReading(label: 'Ин.10:1–9', verses: []),
          ),
          dayStoryProvider.overrideWith(
            (ref, url) async => const DayStory(paragraphs: ['Житие']),
          ),
          verseOfDayProvider.overrideWith(
            (ref, key) async =>
                throw const AppFailure('Нет сети', kind: FailureKind.network),
          ),
        ],
        child: const MaterialApp(home: DayPreloader(child: SizedBox())),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
