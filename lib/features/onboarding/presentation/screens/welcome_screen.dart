import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/brand_lamp.dart';
import '../providers/providers.dart';

/// Единственный экран онбординга. Показывается один раз, до первого контента.
///
/// Задача — не объяснить механику приложения, а сказать человеку, куда он
/// попал. Персона (Артём, 24, недавно крестился) боится не длинных текстов
/// как таковых, а того, что не поймёт и что тут «не для него»: поэтому экран
/// называет, для кого он, и перечисляет содержимое конкретными
/// существительными, без «мыслей» и «порций».
///
/// Про дозировку не сказано ни слова намеренно: это наша механика, а не его
/// задача, и показать её убедительнее, чем пообещать — следующим экраном
/// будет одна цитата на весь экран.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({required this.onStart, super.key});

  /// Получает контекст ЭТОГО экрана. Вызывающий (сплэш) к моменту тапа уже
  /// размонтирован, и навигация по его контексту падала бы с «This widget
  /// has been unmounted» — снаружи это выглядело молчащей кнопкой.
  final void Function(BuildContext context) onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorsExtension.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              const BrandLamp(height: 84),
              const SizedBox(height: 22),
              Text(
                'Лампада',
                style: AppTheme.quoteStyle(context).copyWith(fontSize: 40),
              ),
              const SizedBox(height: 10),
              Text(
                'Для тех, кто только начал ходить в церковь',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Каждый день здесь то, что сегодня читают за службой: '
                'отрывок Евангелия с толкованием, слово святых, притча. '
                'И курс «Основы веры» — по одной теме в день.',
                style: TextStyle(fontSize: 16, height: 1.6, color: colors.ink),
              ),
              const Spacer(flex: 3),
              Center(
                child: AppPrimaryButton(
                  label: 'Открыть сегодняшний день',
                  color: colors.accent,
                  horizontalPadding: 28,
                  onPressed: () {
                    ref.read(onboardingRepositoryProvider).markShown();
                    onStart(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
