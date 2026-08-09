import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/brand_loading_view.dart';
import '../../../daily_cards/presentation/providers/providers.dart';
import '../../../onboarding/presentation/providers/providers.dart';
import '../../../onboarding/presentation/screens/welcome_screen.dart';
import 'app_shell.dart';

/// Первый экран приложения: качает карточки дня и прогресс, показывая
/// брендинг вместо голого лоадера. Как только оба провайдера готовы —
/// заменяет себя на [AppShell].
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

  void _tryNavigate(bool ready, {required bool onboarded}) {
    if (!ready || _navigated) return;
    _navigated = true;
    final wait = _minSplashDuration - DateTime.now().difference(_shownAt);
    Future.delayed(wait.isNegative ? Duration.zero : wait, () {
      if (!mounted) return;
      _replaceWith(context, onboarded ? const AppShell() : _welcome());
    });
  }

  /// Приветствие показываем ОДИН раз и только перед первым контентом.
  /// Дальше оно сменяется шеллом тем же приёмом, что и сплэш, — так переход
  /// «приветствие → первая карточка» выглядит одним движением.
  ///
  /// Контекст для второго перехода берём из `pageBuilder`, а не из состояния
  /// сплэша: после `pushReplacement` сплэш размонтирован, и обращение к его
  /// `context` бросает «This widget has been unmounted». Внешне это выглядело
  /// как молчащая кнопка.
  Widget _welcome() => WelcomeScreen(
    onStart: (welcomeContext) => _replaceWith(welcomeContext, const AppShell()),
  );

  void _replaceWith(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, secondary) => screen,
        transitionsBuilder: (_, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(todayCardsProvider);
    final progressAsync = ref.watch(dayProgressProvider);
    final onboardingAsync = ref.watch(onboardingShownProvider);

    // Ошибка — тоже готовность: показывать её будет Home своим офлайн-видом,
    // чтобы шелл и брендинг были одни на все состояния.
    _tryNavigate(
      (cardsAsync.hasValue || cardsAsync.hasError) &&
          (progressAsync.hasValue || progressAsync.hasError) &&
          onboardingAsync.hasValue,
      onboarded: onboardingAsync.value ?? true,
    );

    return const Scaffold(body: SafeArea(child: BrandLoadingView()));
  }
}
