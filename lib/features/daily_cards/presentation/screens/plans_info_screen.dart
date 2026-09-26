import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
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
                'Планы — последовательные курсы для чтения в своём темпе. '
                'Нажмите на курс, чтобы открыть текущую тему.',
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
                'Свайп вверх открывает следующую тему, вниз — предыдущую. '
                'Номер темы виден сбоку. Чтобы вернуться к списку планов, '
                'нажмите стрелку назад.',
                style: bodyStyle,
              ),
              const SizedBox(height: 32),
              Text('Личный прогресс', style: sectionStyle),
              const SizedBox(height: 12),
              Text(
                'Прогресс не зависит от календарной даты на экране «Домой». '
                'Приложение запоминает последнюю открытую тему, в том числе '
                'при возвращении к предыдущим темам. Номер темы и полоска '
                'под курсом показывают ваше текущее место; при следующем '
                'открытии чтение продолжится с него.',
                style: bodyStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
