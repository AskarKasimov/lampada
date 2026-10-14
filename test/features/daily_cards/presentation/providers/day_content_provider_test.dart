import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/presentation/providers/day_content_provider.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/day_story/domain/entities/day_story.dart';
import 'package:lampada/features/day_story/presentation/providers/providers.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:lampada/features/reading/presentation/providers/providers.dart';

const _key = '2026-09-15';
const _url = 'https://azbyka.ru/days/pokrov';
const _day = TodayCards(
  title: 'Память дня',
  storyUrl: _url,
  cards: [
    DayCard(
      id: 'reading',
      type: CardType.reading,
      body: 'Ин.10:1',
      source: 'Азбука веры',
      reference: 'Jn.10:1',
    ),
  ],
);
const _reading = DailyReading(
  label: 'Ин.10:1',
  verses: [
    Verse(number: 1, chapter: 10, text: 'Стих', interpretation: 'Толкование'),
  ],
);
const _story = DayStory(
  paragraphs: ['Рассказ'],
  iconUrl: 'https://azbyka.ru/icon.jpg',
);

Future<DayContentState> waitForContent(
  ProviderContainer container,
  String key,
  bool Function(DayContentState) ready,
) async {
  final result = Completer<DayContentState>();
  final subscription = container.listen(dayContentProvider(key), (_, content) {
    if (!result.isCompleted && ready(content)) result.complete(content);
  }, fireImmediately: true);
  try {
    return await result.future.timeout(const Duration(seconds: 3));
  } finally {
    subscription.close();
  }
}

void main() {
  test('карточки и рассказ доступны, пока Евангелие ещё загружается', () async {
    final pending = Completer<DailyReading>();
    final container = ProviderContainer(
      overrides: [
        dayCardsProvider.overrideWith((ref, key) async => _day),
        dailyReadingProvider.overrideWith((ref, reference) => pending.future),
        dayStoryProvider.overrideWith((ref, url) async => _story),
      ],
    );
    addTearDown(container.dispose);
    container.listen(
      dayContentProvider(_key),
      (_, _) {},
      fireImmediately: true,
    );
    final content = await waitForContent(
      container,
      _key,
      (content) => content.cards.hasValue && (content.story?.hasValue ?? false),
    );
    expect(content.cards.requireValue.title, 'Память дня');
    expect(content.story?.requireValue.paragraphs, ['Рассказ']);
    expect(content.iconUrl, 'https://azbyka.ru/icon.jpg');
    expect(content.readingIsLoading, isTrue);
    pending.complete(_reading);
    await waitForContent(
      container,
      _key,
      (content) => content.reading?.hasValue ?? false,
    );
    expect(
      container
          .read(dayContentProvider(_key))
          .reading
          ?.requireValue
          .verses
          .single
          .interpretation,
      'Толкование',
    );
    expect(container.read(dayContentProvider(_key)).readingIsLoading, isFalse);
  });

  test('ошибка Евангелия не скрывает карточки, рассказ и икону', () async {
    final container = ProviderContainer(
      overrides: [
        dayCardsProvider.overrideWith((ref, key) async => _day),
        dailyReadingProvider.overrideWith(
          (ref, reference) async => throw StateError('Нет сети'),
        ),
        dayStoryProvider.overrideWith((ref, url) async => _story),
      ],
    );
    addTearDown(container.dispose);
    container.listen(
      dayContentProvider(_key),
      (_, _) {},
      fireImmediately: true,
    );
    final content = await waitForContent(
      container,
      _key,
      (content) =>
          (content.reading?.hasError ?? false) &&
          (content.story?.hasValue ?? false),
    );
    expect(content.cards.requireValue.title, 'Память дня');
    expect(content.reading?.hasError, isTrue);
    expect(content.readingIsLoading, isFalse);
    expect(content.iconUrl, 'https://azbyka.ru/icon.jpg');
  });

  test(
    'разные даты используют один запрос общего отрывка и рассказа',
    () async {
      final readings = <String>[];
      final stories = <String>[];
      final container = ProviderContainer(
        overrides: [
          dayCardsProvider.overrideWith((ref, key) async => _day),
          dailyReadingProvider.overrideWith((ref, reference) async {
            readings.add(reference);
            return _reading;
          }),
          dayStoryProvider.overrideWith((ref, url) async {
            stories.add(url);
            return _story;
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(
        dayContentProvider(_key),
        (_, _) {},
        fireImmediately: true,
      );
      container.listen(
        dayContentProvider('2026-09-16'),
        (_, _) {},
        fireImmediately: true,
      );
      await waitForContent(
        container,
        '2026-09-16',
        (content) =>
            (content.reading?.hasValue ?? false) &&
            (content.story?.hasValue ?? false),
      );
      expect(readings, ['Jn.10:1']);
      expect(stories, [_url]);
      expect(
        container
            .read(dayContentProvider('2026-09-16'))
            .reading
            ?.requireValue
            .verses
            .single
            .text,
        'Стих',
      );
    },
  );

  test('день без связанных материалов не запускает их загрузку', () async {
    var requests = 0;
    final container = ProviderContainer(
      overrides: [
        dayCardsProvider.overrideWith(
          (ref, key) async => const TodayCards(cards: []),
        ),
        dailyReadingProvider.overrideWith((ref, reference) async {
          requests++;
          return _reading;
        }),
        dayStoryProvider.overrideWith((ref, url) async {
          requests++;
          return _story;
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(
      dayContentProvider(_key),
      (_, _) {},
      fireImmediately: true,
    );
    await waitForContent(container, _key, (content) => content.cards.hasValue);
    expect(requests, 0);
    final content = container.read(dayContentProvider(_key));
    expect(content.cards.hasValue, isTrue);
    expect(content.reading, isNull);
    expect(content.story, isNull);
    expect(content.iconUrl, isNull);
  });
}
