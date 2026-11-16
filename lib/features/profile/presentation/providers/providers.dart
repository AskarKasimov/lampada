import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/repositories/prefs_review_prompt_repository.dart';
import '../../domain/repositories/review_prompt_repository.dart';
import '../../domain/usecases/claim_review_request.dart';
import '../services/profile_actions_service.dart';

final profileActionsServiceProvider = Provider<ProfileActionsService>(
  (ref) => PlatformProfileActionsService(),
);

final reviewPromptRepositoryProvider = Provider<ReviewPromptRepository>(
  (ref) => PrefsReviewPromptRepository(ref.watch(sharedPreferencesProvider)),
);

final claimReviewRequestProvider = Provider<ClaimReviewRequest>(
  (ref) => ClaimReviewRequest(ref.watch(reviewPromptRepositoryProvider)),
);
