import '../../../../core/result/result.dart';

/// Показывали ли экран приветствия. Одно значение, но за интерфейсом:
/// presentation не должен знать про SharedPreferences (правило §2 README).
abstract interface class OnboardingRepository {
  Future<Result<bool>> wasShown();

  Future<Result<void>> markShown();
}
