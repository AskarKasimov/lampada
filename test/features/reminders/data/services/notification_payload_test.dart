import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_section.dart';
import 'package:lampada/features/reminders/data/services/notification_service.dart';

void main() {
  test('раздел записывается в payload и читается обратно', () {
    for (final section in DaySection.values) {
      expect(sectionFromPayload(payloadFor(section)), section);
    }
  });

  test('уведомления старых версий без payload ведут в «Мудрость дня»', () {
    // Расписание прошлой версии ещё неделю живёт в системе.
    expect(sectionFromPayload(null), DaySection.wisdom);
    expect(sectionFromPayload(''), DaySection.wisdom);
    expect(sectionFromPayload('unknown'), DaySection.wisdom);
  });

  test('нажатие несёт раздел, номер напоминания и холодный старт', () {
    final tap = tapFrom(payload: 'story', id: 9, coldStart: true);

    expect(tap.section, DaySection.story);
    expect(tap.id, 9);
    expect(tap.coldStart, isTrue);
  });
}
