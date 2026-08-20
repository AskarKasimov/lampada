import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/profile_actions_service.dart';

final profileActionsServiceProvider = Provider<ProfileActionsService>(
  (ref) => PlatformProfileActionsService(),
);
