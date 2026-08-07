// Единственное место, где presentation фичи видит data.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../daily_cards/presentation/providers/providers.dart'
    show sharedPreferencesProvider;
import '../../data/repositories/prefs_onboarding_repository.dart';
import '../../domain/repositories/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => PrefsOnboardingRepository(ref.watch(sharedPreferencesProvider)),
);

/// Показывали ли приветствие. Читается один раз на сплэше.
final onboardingShownProvider = FutureProvider<bool>((ref) async {
  final result = await ref.watch(onboardingRepositoryProvider).wasShown();
  return switch (result) {
    Success(value: final shown) => shown,
    // Сбой чтения трактуем как «показывали»: встретить приветствием того,
    // кто пользуется приложением давно, хуже, чем не показать его новичку.
    Failure() => true,
  };
});
