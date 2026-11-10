import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../repositories/review_prompt_repository.dart';

/// Решает, пора ли попросить оценку, и сразу отмечает момент использованным:
/// так один и тот же момент не попросит оценку дважды. Сбой хранилища
/// трактуем как «не просить»: лишний системный диалог хуже пропущенного.
class ClaimReviewRequest {
  ClaimReviewRequest(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ReviewPromptRepository _repository;
  final DateTime Function() _clock;

  /// Юзер закрыл раздел, неважно, дочитав ли его.
  Future<bool> afterReading() async {
    final state = await _load();
    if (state == null || state.requested.contains(ReviewMoment.firstReading)) {
      return false;
    }
    return _mark(state, ReviewMoment.firstReading);
  }

  /// Юзер открыл приложение. Первый вход запоминает день; в любой более
  /// поздний день оценку просим один раз.
  Future<bool> onAppOpen() async {
    final state = await _load();
    if (state == null) return false;
    final today = dateKey(_clock());
    final firstOpenDay = state.firstOpenDay;
    if (firstOpenDay == null) {
      await _repository.save((firstOpenDay: today, requested: state.requested));
      return false;
    }
    if (today.compareTo(firstOpenDay) <= 0 ||
        state.requested.contains(ReviewMoment.nextDayReturn)) {
      return false;
    }
    return _mark(state, ReviewMoment.nextDayReturn);
  }

  Future<ReviewPromptState?> _load() async =>
      switch (await _repository.load()) {
        Success(value: final state) => state,
        Failure() => null,
      };

  Future<bool> _mark(ReviewPromptState state, ReviewMoment moment) async {
    final saved = await _repository.save((
      firstOpenDay: state.firstOpenDay,
      requested: {...state.requested, moment},
    ));
    return saved is Success;
  }
}
