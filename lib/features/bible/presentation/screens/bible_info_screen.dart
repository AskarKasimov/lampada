import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Поясняет перевод и статусы плиток глав в каталоге Библии.
class BibleInfoScreen extends StatelessWidget {
  const BibleInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.background,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Русский Синодальный перевод',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Здесь собрана вся Библия в русском Синодальном переводе. '
                'Выберите книгу и главу, чтобы начать чтение.',
                style: TextStyle(fontSize: 17, height: 1.5, color: colors.ink),
              ),
              const SizedBox(height: 40),
              Text(
                'Статусы глав',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 20),
              _StatusExample(
                number: '3',
                label: 'Прочитанная глава',
                description: 'Вы дошли до последнего стиха главы.',
                background: colors.accent,
                numberColor: colors.background,
              ),
              const SizedBox(height: 20),
              _StatusExample(
                number: '4',
                label: 'Доступна офлайн',
                description: 'Текст главы уже скачан и откроется без сети.',
                background: colors.background,
                numberColor: colors.accent,
                border: BorderSide(color: colors.accent, width: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusExample extends StatelessWidget {
  const _StatusExample({
    required this.number,
    required this.label,
    required this.description,
    required this.background,
    required this.numberColor,
    this.border = BorderSide.none,
  });

  final String number;
  final String label;
  final String description;
  final Color background;
  final Color numberColor;
  final BorderSide border;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Row(
      children: [
        Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
            side: border,
          ),
          child: SizedBox(
            width: 58,
            height: 44,
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: numberColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
