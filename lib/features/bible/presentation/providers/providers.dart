import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../data/datasources/bible_remote_datasource.dart';
import '../../data/repositories/azbyka_bible_repository.dart';
import '../../domain/entities/bible_chapter.dart';
import '../../domain/repositories/bible_repository.dart';
import '../../domain/usecases/get_bible_chapter.dart';

final bibleRepositoryProvider = Provider<BibleRepository>(
  (ref) => AzbykaBibleRepository(AzbykaBibleRemoteDatasource()),
);

final getBibleChapterProvider = Provider<GetBibleChapter>(
  (ref) => GetBibleChapter(ref.watch(bibleRepositoryProvider)),
);

final bibleChapterProvider = FutureProvider.family<BibleChapter, (String, int)>(
  (ref, key) async {
    final result = await ref.watch(getBibleChapterProvider)(key.$1, key.$2);
    return switch (result) {
      Success(value: final chapter) => chapter,
      Failure(failure: final failure) => throw failure,
    };
  },
);
