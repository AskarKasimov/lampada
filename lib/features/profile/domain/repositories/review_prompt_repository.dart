import '../../../../core/result/result.dart';

/// Когда приложение само просит оценку. Каждый момент срабатывает один раз.
enum ReviewMoment {
  /// Юзер впервые закрыл любой раздел, даже не дочитав.
  firstReading,

  /// Юзер закрыл раздел в один из дней после первого входа.
  nextDayReturn,

  /// Юзер открыл приложение в один из дней после первого входа.
  laterDayOpen,
}

/// Что известно о запросах оценки: день первого входа и день последнего
/// запроса (`yyyy-MM-dd`) и уже использованные моменты.
typedef ReviewPromptState = ({
  String? firstOpenDay,
  String? lastRequestDay,
  Set<ReviewMoment> requested,
});

/// Хранилище состояния запросов оценки. Реализация — в data.
abstract interface class ReviewPromptRepository {
  Future<Result<ReviewPromptState>> load();

  Future<Result<void>> save(ReviewPromptState state);
}
