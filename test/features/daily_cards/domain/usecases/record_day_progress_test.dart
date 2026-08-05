import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/record_card_read.dart';

const _cards = [DayCard(id: 'q', type: CardType.quote, body: 'b', source: 's')];

const _fresh = TodayCards(cards: _cards);
final _stale = TodayCards(cards: _cards, staleDate: DateTime(2026, 7, 19));

/// Пишет в память и считает вызовы — usecase не должен звать репозиторий,
/// когда сессия на устаревших карточках.
class _SpyRepository implements DayProgressRepository {
  final List<String> calls = [];
  Set<CardType> _read = {};
  Set<String> _visited = {};

  DayProgress get _current =>
      DayProgress(readTypes: _read, visitedDays: _visited);

  @override
  Future<Result<DayProgress>> loadToday() async {
    calls.add('loadToday');
    return Success(_current);
  }

  @override
  Future<Result<DayProgress>> markRead(CardType type) async {
    calls.add('markRead');
    _read = {..._read, type};
    _visited = {..._visited, dateKey(DateTime.now())};
    return Success(_current);
  }
}

void main() {
  group('RecordCardRead', () {
    test('свежая сессия — карточка засчитывается', () async {
      final repo = _SpyRepository();

      final result = await RecordCardRead(repo)(
        CardType.quote,
        session: _fresh,
      );

      expect(repo.calls, ['markRead']);
      expect(
        (result as Success<DayProgress>).value.readTypes,
        contains(CardType.quote),
      );
    });

    test('свежая сессия зажигает сегодняшний день', () async {
      // «Лампадка» отмечает дни с активностью, и первая же карточка
      // делает день состоявшимся (§1).
      final repo = _SpyRepository();

      final result = await RecordCardRead(repo)(
        CardType.quote,
        session: _fresh,
      );

      expect(
        (result as Success<DayProgress>).value.isLit(DateTime.now()),
        isTrue,
      );
    });

    test('устаревшая сессия — прогресс не пишется', () async {
      final repo = _SpyRepository();

      final result = await RecordCardRead(repo)(
        CardType.quote,
        session: _stale,
      );

      expect(repo.calls, isNot(contains('markRead')));
      expect((result as Success<DayProgress>).value.readTypes, isEmpty);
    });

    test('устаревшая сессия не зажигает сегодняшний день', () async {
      // Сегодняшнего контента юзер не видел — обещать «огонёк зажжён»
      // было бы тихой неправдой.
      final repo = _SpyRepository();

      final result = await RecordCardRead(repo)(
        CardType.quote,
        session: _stale,
      );

      expect((result as Success<DayProgress>).value.visitedDays, isEmpty);
    });

    test(
      'устаревшая сессия отдаёт актуальный прогресс, а не пустышку',
      () async {
        final repo = _SpyRepository();
        // День уже частично пройден по свежим карточкам.
        await RecordCardRead(repo)(CardType.quote, session: _fresh);

        final result = await RecordCardRead(repo)(
          CardType.advice,
          session: _stale,
        );

        expect(
          (result as Success<DayProgress>).value.readTypes,
          contains(CardType.quote),
        );
      },
    );
  });
}
