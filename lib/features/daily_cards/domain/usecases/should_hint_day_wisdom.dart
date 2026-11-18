import '../../../../core/result/result.dart';
import '../entities/day_progress.dart';
import '../repositories/wisdom_hint_repository.dart';

/// Решает, прыгать ли плитке «Мудрости дня» на главной.
///
/// После отмены обязательного показа до неё доходит только половина
/// новичков, а дочитавшие её возвращаются заметно чаще. Поэтому плитка зовёт
/// к себе, пока юзер ни разу её не открыл. Отметки открытия до этой
/// подсказки не было: кто уже дочитывал «Мудрость дня», её не видит.
class ShouldHintDayWisdom {
  ShouldHintDayWisdom(this._hints);

  final WisdomHintRepository _hints;

  Future<bool> call(DayProgress progress) async {
    if (progress.wisdomCompletedDays.isNotEmpty) return false;
    // Не смогли прочитать отметку: лучше не прыгать, чем прыгать вечно.
    return switch (await _hints.wisdomOpened()) {
      Success(value: final opened) => !opened,
      Failure() => false,
    };
  }
}
