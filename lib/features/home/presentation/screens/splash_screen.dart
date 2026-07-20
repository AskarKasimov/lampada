import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../daily_cards/presentation/providers/providers.dart';
import '../widgets/brand_loading_view.dart';
import 'home_screen.dart';

/// Первый экран приложения: качает карточки дня и прогресс, показывая
/// брендинг вместо голого лоадера. Как только оба провайдера готовы —
/// заменяет себя на [HomeScreen].
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

/// Даже когда данные из кэша приходят мгновенно, сплэш держим хотя бы
/// это время — иначе брендинг просто мелькает.
const _minSplashDuration = Duration(milliseconds: 700);

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final _shownAt = DateTime.now();
  bool _navigated = false;

  void _tryNavigate(bool ready) {
    if (!ready || _navigated) return;
    _navigated = true;
    final wait = _minSplashDuration - DateTime.now().difference(_shownAt);
    Future.delayed(wait.isNegative ? Duration.zero : wait, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
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

    // Ошибка — тоже готовность: показывать её будет Home своим офлайн-видом,
    // чтобы шелл и брендинг были одни на все состояния.
    _tryNavigate(
      (cardsAsync.hasValue || cardsAsync.hasError) &&
          (progressAsync.hasValue || progressAsync.hasError),
    );

    return const Scaffold(
      body: SafeArea(child: BrandLoadingView(heroTag: 'lampada')),
    );
  }
}
