import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/domain/course_calendar.dart';

void main() {
  group('дата темы курса', () {
    test('номер темы = день года — подтверждено на живых страницах', () {
      // Эти пары сняты с azbyka.ru: 2 января там Тема 2, 5 марта Тема 64,
      // 20 мая Тема 140, 28 июля Тема 209, 11 ноября Тема 315.
      final cases = {
        2: DateTime(2026, 1, 2),
        64: DateTime(2026, 3, 5),
        140: DateTime(2026, 5, 20),
        209: DateTime(2026, 7, 28),
        315: DateTime(2026, 11, 11),
      };

      cases.forEach((topic, expected) {
        expect(dateForCourseTopic(topic), expected, reason: 'тема $topic');
      });
    });

    test('первая тема — 1 января опорного года', () {
      expect(dateForCourseTopic(1), DateTime(2026, 1, 1));
    });

    test('последняя тема попадает в 31 декабря', () {
      // Опорный год невисокосный: иначе появился бы 366-й день, которому
      // не соответствует ни одна тема.
      expect(dateForCourseTopic(courseTopicCount), DateTime(2026, 12, 31));
    });

    test('день года действительно равен номеру темы для всего курса', () {
      for (var topic = 1; topic <= courseTopicCount; topic++) {
        final date = dateForCourseTopic(topic);
        expect(date.difference(DateTime(2026, 1, 1)).inDays + 1, topic);
      }
    });
  });

  group('нормализация номера', () {
    test('курс замкнут: после последней темы снова первая', () {
      expect(normalizeCourseTopic(courseTopicCount + 1), 1);
      expect(normalizeCourseTopic(courseTopicCount + 2), 2);
    });

    test('номер в диапазоне не меняется', () {
      expect(normalizeCourseTopic(1), 1);
      expect(normalizeCourseTopic(209), 209);
      expect(normalizeCourseTopic(courseTopicCount), courseTopicCount);
    });

    test('мусор из prefs приводится к первой теме', () {
      expect(normalizeCourseTopic(0), 1);
      expect(normalizeCourseTopic(-5), 1);
    });
  });
}
