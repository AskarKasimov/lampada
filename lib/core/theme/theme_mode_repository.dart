import 'package:flutter/material.dart';

import '../result/result.dart';

abstract interface class ThemeModeRepository {
  Result<ThemeMode> load();

  Future<Result<void>> save(ThemeMode mode);
}
