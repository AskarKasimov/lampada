/// Вид сбоя. Живёт в core, потому что его проставляет data (репозиторий) и
/// разворачивает в текст presentation — дублировать enum по слоям незачем.
enum FailureKind {
  /// Нет сети, таймаут, обрыв соединения. Ретраибельно.
  network,

  /// Сервер ответил, но не 200. Ретраибельно.
  server,

  /// Разметка страницы поменялась, сбой стораджа, всё прочее. Не ретраибельно.
  unknown,
}

/// Ошибка уровня приложения. Не пересекает границу domain как исключение —
/// всегда упакована в [Failure].
class AppFailure implements Exception {
  const AppFailure(this.message, {required this.kind, this.cause});

  final String message;
  final FailureKind kind;
  final Object? cause;

  @override
  String toString() => 'AppFailure($message, ${kind.name})';
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
