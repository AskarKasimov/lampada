import '../../../../core/result/result.dart';
import '../entities/bible_reading_position.dart';
import '../repositories/bible_repository.dart';

class LoadBibleReadingPosition {
  const LoadBibleReadingPosition(this._repository);

  final BibleRepository _repository;

  Future<Result<BibleReadingPosition?>> call() =>
      _repository.getReadingPosition();
}
