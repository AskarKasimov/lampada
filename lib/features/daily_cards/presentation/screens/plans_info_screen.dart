import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Руководство по личным курсам и сохранению текущей темы.
class PlansInfoScreen extends StatelessWidget {
  const PlansInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final bodyStyle = TextStyle(fontSize: 17, height: 1.5, color: colors.ink);
    final sectionStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: colors.ink,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.background,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding:
              AppSpacing.of(context).horizontal +
              const EdgeInsets.only(top: 24, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Как проходить планы',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Личный курс находится на главной странице; читайте в своём '
                'темпе. Нажмите на курс, чтобы продолжить с сохранённого места.',
                style: bodyStyle,
              ),
              const SizedBox(height: 32),
              Text('Основы веры', style: sectionStyle),
              const SizedBox(height: 12),
              Text(
                'Сейчас доступен один курс: 365 тем об основах православной веры '
                'по материалам «Азбуки веры». Можно читать по одной теме в день '
                'или двигаться в удобном темпе.',
                style: bodyStyle,
              ),
              const SizedBox(height: 32),
              Text('Чтение тем', style: sectionStyle),
              const SizedBox(height: 12),
              Text(
                'Свайп вверх открывает следующий фрагмент текста, вниз — предыдущий. '
                'Точки слева показывают прогресс внутри темы. '
                'После карточки завершения следующий свайп открывает новую тему. '
                'Стрелка назад возвращает на главную страницу.',
                style: bodyStyle,
              ),
              const SizedBox(height: 32),
              Text('Личный прогресс', style: sectionStyle),
              const SizedBox(height: 12),
              Text(
                'Прогресс не зависит от календарной даты на экране «Домой». '
                'Карточка «Тема прочитана» после текста завершает тему и отмечает чтение дня. '
                'Полоска под курсом показывает '
                'число завершённых тем; при следующем открытии чтение продолжится '
                'с последней просмотренной карточки. После всех 365 тем курс пройден, '
                'но можно вернуться к любой теме для повторного чтения.',
                style: bodyStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
