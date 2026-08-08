import 'package:flutter/material.dart';

import '../result/result.dart';
import 'theme_mode_repository.dart';

class LoadThemeMode {
  const LoadThemeMode(this._repository);

  final ThemeModeRepository _repository;

  Result<ThemeMode> call() => _repository.load();
}

class SaveThemeMode {
  const SaveThemeMode(this._repository);

  final ThemeModeRepository _repository;

  Future<Result<void>> call(ThemeMode mode) => _repository.save(mode);
}
