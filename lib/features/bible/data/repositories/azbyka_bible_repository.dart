import '../../../../core/network/remote_fetch_exception.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/bible_chapter.dart';
import '../../domain/repositories/bible_repository.dart';
import '../datasources/bible_remote_datasource.dart';
import '../mappers/bible_chapter_mapper.dart';

class AzbykaBibleRepository implements BibleRepository {
  const AzbykaBibleRepository(this._source);

  final BibleRemoteDatasource _source;

  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) async {
    try {
      return Success((await _source.fetchChapter(book, chapter)).toEntity());
    } on RemoteFetchException catch (error) {
      return Failure(
        AppFailure(
          'Не удалось загрузить главу',
          kind: error.kind,
          cause: error,
        ),
      );
    } on Exception catch (error) {
      return Failure(
        AppFailure(
          'Не удалось прочитать главу',
          kind: FailureKind.unknown,
          cause: error,
        ),
      );
    }
  }
}
