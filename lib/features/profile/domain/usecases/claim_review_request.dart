import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../repositories/review_prompt_repository.dart';

/// Решает, пора ли попросить оценку, и сразу отмечает момент использованным:
/// так один и тот же момент не попросит оценку дважды. Сбой хранилища
/// трактуем как «не просить»: лишний системный диалог хуже пропущенного.
///
/// Больше одного запроса в день не показываем: несработавший в этот день
/// момент ждёт следующего.
class ClaimReviewRequest {
  ClaimReviewRequest(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ReviewPromptRepository _repository;
  final DateTime Function() _clock;

  /// Юзер открыл приложение: первый вход запоминает день, оценку не просит.
  /// Так вход отмечается, когда при нём уже показали другое системное окно.
  Future<void> recordAppOpen() async {
    final state = await _load();
    if (state == null || state.firstOpenDay != null) return;
    await _repository.save((
      firstOpenDay: dateKey(_clock()),
      lastRequestDay: state.lastRequestDay,
      requested: state.requested,
    ));
  }

  /// Юзер открыл приложение. Первый вход только запоминает день, а вход в
  /// любой из следующих дней один раз просит оценку
  /// ([ReviewMoment.laterDayOpen]). Возвращает, нужно ли просить.
  Future<bool> afterAppOpen() async {
    final state = await _load();
    if (state == null) return false;
    final today = dateKey(_clock());
    final firstOpenDay = state.firstOpenDay;
    if (firstOpenDay == null) {
      await _repository.save((
        firstOpenDay: today,
        lastRequestDay: state.lastRequestDay,
        requested: state.requested,
      ));
      return false;
    }
    if (today.compareTo(firstOpenDay) <= 0 ||
        state.lastRequestDay == today ||
        state.requested.contains(ReviewMoment.laterDayOpen)) {
      return false;
    }
    return _use(state, firstOpenDay, today, {ReviewMoment.laterDayOpen});
  }

  /// Юзер закрыл раздел, дочитав его или крестиком. Первое закрытие
  /// просит оценку ([ReviewMoment.firstReading]), а первое закрытие в
  /// любой день после первого входа просит ещё раз
  /// ([ReviewMoment.nextDayReturn]). Возвращает использованный момент или
  /// null, если просить не нужно.
  ///
  /// Если первое закрытие случилось уже не в день первого входа, оно
  /// закрывает оба момента: одно окно вместо двух.
  Future<ReviewMoment?> afterReading() async {
    final state = await _load();
    if (state == null) return null;
    final today = dateKey(_clock());
    if (state.lastRequestDay == today) return null;
    final firstOpenDay = state.firstOpenDay ?? today;
    final laterDay = today.compareTo(firstOpenDay) > 0;
    final requested = state.requested;
    final ReviewMoment moment;
    if (!requested.contains(ReviewMoment.firstReading)) {
      moment = ReviewMoment.firstReading;
    } else if (laterDay && !requested.contains(ReviewMoment.nextDayReturn)) {
      moment = ReviewMoment.nextDayReturn;
    } else {
      return null;
    }
    final used = await _use(state, firstOpenDay, today, {
      moment,
      if (laterDay) ReviewMoment.nextDayReturn,
    });
    return used ? moment : null;
  }

  Future<bool> _use(
    ReviewPromptState state,
    String firstOpenDay,
    String today,
    Set<ReviewMoment> moments,
  ) async {
    final saved = await _repository.save((
      firstOpenDay: firstOpenDay,
      lastRequestDay: today,
      requested: {...state.requested, ...moments},
    ));
    return saved is Success;
  }

  Future<ReviewPromptState?> _load() async =>
      switch (await _repository.load()) {
        Success(value: final state) => state,
        Failure() => null,
      };
}
