import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/complete_day.dart';
import 'package:lampada/features/daily_cards/domain/usecases/record_card_read.dart';

const _cards = [
  DayCard(id: 'q', type: CardType.quote, body: 'b', source: 's'),
];

const _fresh = TodayCards(cards: _cards);
final _stale = TodayCards(cards: _cards, staleDate: DateTime(2026, 7, 19));

/// Пишет в память и считает вызовы — usecase не должен звать репозиторий,
/// когда сессия на устаревших карточках.
class _SpyRepository implements DayProgressRepository {
  final List<String> calls = [];
  Set<CardType> _read = {};
  int _streak = 0;

  DayProgress get _current =>
      DayProgress(readTypes: _read, streakDays: _streak);

  @override
  Future<Result<DayProgress>> loadToday() async {
    calls.add('loadToday');
    return Success(_current);
  }

  @override
  Future<Result<DayProgress>> markRead(CardType type) async {
    calls.add('markRead');
    _read = {..._read, type};
    return Success(_current);
  }

  @override
  Future<Result<DayProgress>> completeDay() async {
    calls.add('completeDay');
    _streak += 1;
    return Success(_current);
  }
}

void main() {
  group('RecordCardRead', () {
    test('свежая сессия — карточка засчитывается', () async {
      final repo = _SpyRepository();

      final result =
          await RecordCardRead(repo)(CardType.quote, session: _fresh);

      expect(repo.calls, ['markRead']);
      expect((result as Success<DayProgress>).value.readTypes,
          contains(CardType.quote));
    });

    test('устаревшая сессия — прогресс не пишется', () async {
      final repo = _SpyRepository();

      final result =
          await RecordCardRead(repo)(CardType.quote, session: _stale);

      expect(repo.calls, isNot(contains('markRead')));
      expect((result as Success<DayProgress>).value.readTypes, isEmpty);
    });
  });

  group('CompleteDay', () {
    test('свежая сессия — серия растёт', () async {
      final repo = _SpyRepository();

      final result = await CompleteDay(repo)(session: _fresh);

      expect(repo.calls, ['completeDay']);
      expect((result as Success<DayProgress>).value.streakDays, 1);
    });

    test('устаревшая сессия — серия не растёт', () async {
      final repo = _SpyRepository();

      final result = await CompleteDay(repo)(session: _stale);

      expect(repo.calls, isNot(contains('completeDay')));
      expect((result as Success<DayProgress>).value.streakDays, 0);
    });

    test('устаревшая сессия отдаёт актуальный прогресс, а не пустышку',
        () async {
      final repo = _SpyRepository();
      // День уже частично пройден по свежим карточкам.
      await RecordCardRead(repo)(CardType.quote, session: _fresh);

      final result = await CompleteDay(repo)(session: _stale);

      expect((result as Success<DayProgress>).value.readTypes,
          contains(CardType.quote));
    });
  });
}
