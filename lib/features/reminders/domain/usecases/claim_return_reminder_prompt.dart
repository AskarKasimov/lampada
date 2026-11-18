import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../repositories/return_prompt_repository.dart';

/// Решает, пора ли при входе показать системный запрос уведомлений, и сразу
/// отмечает момент использованным.
///
/// Первый вход запоминает день. В любой более поздний день запрос
/// срабатывает один раз: кто отложил напоминания на нашем экране, системного
/// окна ещё не видел, а с разрешёнными напоминаниями возвращаются заметно
/// чаще. Сбой хранилища трактуем как «не спрашивать»: системное окно
/// каждый день хуже пропущенного.
class ClaimReturnReminderPrompt {
  ClaimReturnReminderPrompt(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ReturnPromptRepository _repository;
  final DateTime Function() _clock;

  Future<bool> call() async {
    final state = switch (await _repository.load()) {
      Success(value: final state) => state,
      Failure() => null,
    };
    if (state == null || state.prompted) return false;
    final today = dateKey(_clock());
    final firstOpenDay = state.firstOpenDay;
    if (firstOpenDay == null) {
      await _repository.save((firstOpenDay: today, prompted: false));
      return false;
    }
    if (today.compareTo(firstOpenDay) <= 0) return false;
    final saved = await _repository.save((
      firstOpenDay: firstOpenDay,
      prompted: true,
    ));
    return saved is Success;
  }
}
