import '../../../../core/result/result.dart';

/// Когда приложение само просит оценку. Каждый момент срабатывает один раз.
enum ReviewMoment {
  /// Юзер впервые закрыл любой раздел, даже не дочитав.
  firstReading,

  /// Юзер открыл приложение в один из дней после первого входа.
  nextDayReturn,
}

/// Что известно о запросах оценки: день первого входа (`yyyy-MM-dd`) и уже
/// использованные моменты.
typedef ReviewPromptState = ({
  String? firstOpenDay,
  Set<ReviewMoment> requested,
});

/// Хранилище состояния запросов оценки. Реализация — в data.
abstract interface class ReviewPromptRepository {
  Future<Result<ReviewPromptState>> load();

  Future<Result<void>> save(ReviewPromptState state);
}
