import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Спокойная благородная тема. TODO: тёмная тема.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          surface: AppColors.background,
        ),
      );

  /// Курсивный serif для цитаты/мысли дня — единственное место, где
  /// используется Lora, остальной UI — системный шрифт.
  static TextStyle get quoteStyle => GoogleFonts.lora(
        fontSize: 24,
        height: 1.6,
        fontStyle: FontStyle.italic,
        color: AppColors.ink,
      );
}
