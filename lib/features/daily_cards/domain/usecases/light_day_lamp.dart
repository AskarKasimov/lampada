import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../entities/day_progress.dart';
import '../repositories/day_progress_repository.dart';

/// Итог попытки зажечь «Лампадку»: прогресс после неё, загорелся ли
/// сегодняшний день именно сейчас и началась ли серия заново.
typedef DayLampResult = ({DayProgress progress, bool litNow, bool restarted});

/// Зажигает сегодняшнюю «Лампадку», когда раздел дочитан до конца: рассказ
/// «Памяти дня» или глава Библии. «Мудрость дня» и тема курса зажигают её
/// своими use case вместе с собственной отметкой.
///
/// Засчитывается только сегодня. [contentDate] — день, к которому относится
/// раздел; если он уже не сегодняшний (экран открыт до полуночи), лампада
/// не зажигается ни за тот день, ни за сегодня. Без даты раздел не привязан
/// к календарю, и его дочитывание засчитывает текущий день.
class LightDayLamp {
  LightDayLamp(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DayProgressRepository _repository;
  final DateTime Function() _clock;

  Future<Result<DayLampResult>> call({DateTime? contentDate}) async {
    final now = _clock();
    final DayProgress before;
    switch (await _repository.loadToday()) {
      case Failure(failure: final failure):
        return Failure(failure);
      case Success(value: final progress):
        before = progress;
    }
    final countsToday =
        contentDate == null || dateKey(contentDate) == dateKey(now);
    if (!countsToday || before.isLit(now)) {
      return Success((progress: before, litNow: false, restarted: false));
    }
    switch (await _repository.markVisited(date: now)) {
      case Failure(failure: final failure):
        return Failure(failure);
      case Success(value: final after):
        return Success((
          progress: after,
          litNow: after.isLit(now),
          restarted: before.streakOn(now) == 0,
        ));
    }
  }
}
