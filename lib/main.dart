import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/daily_cards/presentation/screens/daily_card_screen.dart';

void main() {
  runApp(const ProviderScope(child: LampadaApp()));
}

class LampadaApp extends StatelessWidget {
  const LampadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Лампада',
      theme: AppTheme.light,
      home: const DailyCardScreen(),
    );
  }
}
