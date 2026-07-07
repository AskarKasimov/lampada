import 'package:flutter/material.dart';

/// Заглушка «спокойной благородной» темы.
/// TODO: типографика, палитра, тёмная тема.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8D6E63)),
        fontFamily: null, // TODO: благородный serif для карточек
      );
}
