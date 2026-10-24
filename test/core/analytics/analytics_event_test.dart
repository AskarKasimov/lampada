import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_event.dart';

void main() {
  test('значения перечислений уходят в snake_case', () {
    final event = AnalyticsEvent.bibleChapterOpened(
      book: 'Jn',
      chapter: 1,
      source: BibleOpenSource.dailyReading,
    );

    expect(event.name, 'bible_chapter_opened');
    expect(event.params, {
      'book': 'Jn',
      'chapter': 1,
      'source': 'daily_reading',
    });
  });

  test('необязательные параметры без значения не отправляются', () {
    final event = AnalyticsEvent.reminderPromptAnswered(
      choice: ReminderPromptChoice.later,
    );

    expect(event.params, {'choice': 'later'});
  });

  test('имена всех событий в snake_case', () {
    final samples = [
      AnalyticsEvent.onboardingStepViewed(OnboardingStep.reader),
      AnalyticsEvent.onboardingCompleted(),
      AnalyticsEvent.notificationOpened(
        section: AnalyticsSection.story,
        slot: ReminderSlot.afterWisdom,
        coldStart: true,
      ),
      AnalyticsEvent.contentLoadFailed(
        content: LoadedContent.bibleChapter,
        kind: 'network',
      ),
    ];

    for (final event in samples) {
      expect(event.name, matches(RegExp(r'^[a-z]+(_[a-z]+)*$')));
      for (final value in event.params.values.whereType<String>()) {
        expect(value, matches(RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$')));
      }
    }
  });
}
