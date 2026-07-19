// lib/features/home/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../daily_cards/presentation/providers/providers.dart';
import '../widgets/brand_mark.dart';
import 'home_screen.dart';

/// Первый экран приложения: качает карточки дня и прогресс, показывая
/// брендинг вместо голого лоадера. Как только оба провайдера готовы —
/// заменяет себя на [HomeScreen].
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  void _tryNavigate(bool ready) {
    if (!ready || _navigated) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, animation, secondary) => const HomeScreen(),
          transitionsBuilder: (_, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(todayCardsProvider);
    final progressAsync = ref.watch(dayProgressProvider);

    _tryNavigate(cardsAsync.hasValue && progressAsync.hasValue);

    final error = cardsAsync.error ?? progressAsync.error;
    final colors = AppColorsExtension.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(),
                if (error != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Не удалось загрузить карточки',
                    style: TextStyle(fontSize: 13, color: colors.homeSubtitle),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(todayCardsProvider);
                      ref.invalidate(dayProgressProvider);
                    },
                    style: TextButton.styleFrom(foregroundColor: colors.link),
                    child: Text(
                      'Повторить',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: colors.link,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
