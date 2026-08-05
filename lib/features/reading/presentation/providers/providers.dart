// Единственное место, где presentation фичи видит data.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_status_provider.dart';
import '../../../../core/result/result.dart';
import '../../../daily_cards/presentation/providers/providers.dart'
    show sharedPreferencesProvider;
import '../../data/datasources/reading_remote_datasource.dart';
import '../../data/repositories/azbyka_reading_repository.dart';
import '../../domain/entities/daily_reading.dart';
import '../../domain/repositories/reading_repository.dart';
import '../../domain/usecases/get_daily_reading.dart';

final readingRepositoryProvider = Provider<ReadingRepository>(
  (ref) => AzbykaReadingRepository(
    AzbykaReadingRemoteDatasource(),
    ref.watch(sharedPreferencesProvider),
    networkStatus: ref.watch(networkStatusProvider),
  ),
);

final getDailyReadingProvider = Provider<GetDailyReading>(
  (ref) => GetDailyReading(ref.watch(readingRepositoryProvider)),
);

/// Чтение по ссылке отрывка. Family, а не единичный провайдер: календарь
/// открывает чужие дни, и отрывок там свой.
final dailyReadingProvider = FutureProvider.family<DailyReading, String>((
  ref,
  reference,
) async {
  final result = await ref.watch(getDailyReadingProvider)(reference);
  return switch (result) {
    Success(value: final reading) => reading,
    Failure(failure: final f) => throw f,
  };
});
