import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/repositories/wisdom_hint_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/should_hint_day_wisdom.dart';

class _MemoryHints implements WisdomHintRepository {
  _MemoryHints({this.opened = false, this.fails = false});

  bool opened;
  final bool fails;

  @override
  Future<Result<bool>> wisdomOpened() async => fails
      ? const Failure(AppFailure('Нет доступа', kind: FailureKind.unknown))
      : Success(opened);

  @override
  Future<Result<void>> markWisdomOpened() async {
    opened = true;
    return const Success(null);
  }

  @override
  Result<Set<CardType>> introducedSections() => const Success({});

  @override
  Future<Result<void>> markSectionIntroduced(CardType type) async =>
      const Success(null);
}

const _fresh = DayProgress(readTypes: {}, visitedDays: {});

void main() {
  test(
    'новичку, который ещё не открывал «Мудрость дня», подсказываем',
    () async {
      expect(await ShouldHintDayWisdom(_MemoryHints())(_fresh), isTrue);
    },
  );

  test('после первого открытия подсказки нет', () async {
    expect(
      await ShouldHintDayWisdom(_MemoryHints(opened: true))(_fresh),
      isFalse,
    );
  });

  test('дочитавший её до обновления подсказку не видит', () async {
    const veteran = DayProgress(
      readTypes: {},
      visitedDays: {},
      wisdomCompletedDays: {'2026-11-01'},
    );
    expect(await ShouldHintDayWisdom(_MemoryHints())(veteran), isFalse);
  });

  test('не смогли прочитать отметку: не прыгаем', () async {
    expect(
      await ShouldHintDayWisdom(_MemoryHints(fails: true))(_fresh),
      isFalse,
    );
  });
}
