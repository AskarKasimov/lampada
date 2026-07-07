// lib/core/result/result.dart

/// Ошибка уровня приложения. Не пересекает границу domain как исключение —
/// всегда упакована в [Failure].
class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppFailure($message)';
}

/// Результат операции: [Success] или [Failure].
/// Usecase возвращает Result, UI разворачивает через switch.
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);
  final AppFailure failure;
}
