import '../result/result.dart';

/// Сбой похода в сеть с уже определённым видом. Источник и репозиторий
/// разделяют его, чтобы репозиторий мог решить, ретраить ли запрос.
class RemoteFetchException implements Exception {
  const RemoteFetchException(this.kind, this.cause);

  final FailureKind kind;
  final Object cause;

  @override
  String toString() => 'RemoteFetchException(${kind.name}, $cause)';
}
