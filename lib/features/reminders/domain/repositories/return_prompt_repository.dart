import '../../../../core/result/result.dart';

/// Что известно о системном запросе уведомлений при возвращении: день
/// первого входа (`yyyy-MM-dd`) и был ли запрос уже показан.
typedef ReturnPromptState = ({String? firstOpenDay, bool prompted});

/// Хранилище состояния запроса при возвращении. Реализация — в data.
abstract interface class ReturnPromptRepository {
  Future<Result<ReturnPromptState>> load();

  Future<Result<void>> save(ReturnPromptState state);
}
