import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/day_progress.dart';

const _lampOn = 'assets/illustrations/lampada_on.png';
const _lampOff = 'assets/illustrations/lampada_off.png';

/// «1 день подряд», «3 дня подряд», «5 дней подряд».
String streakDaysLabel(int days) {
  final mod100 = days % 100;
  final mod10 = days % 10;
  if (mod100 >= 11 && mod100 <= 14) return 'дней подряд';
  if (mod10 == 1) return 'день подряд';
  if (mod10 >= 2 && mod10 <= 4) return 'дня подряд';
  return 'дней подряд';
}

/// Серия дней («Лампадка») на главной: лампада, число дней и одна фраза.
/// Ряда дней недели нет намеренно: неделя уже есть в полоске наверху, а
/// второй такой ряд с другим смыслом путал бы.
class StreakCard extends StatelessWidget {
  const StreakCard({required this.progress, required this.today, super.key});

  final DayProgress progress;
  final DateTime today;

  String _message(int streak, bool litToday) {
    // Тон как у трекеров привычек: сначала поддержать, потом мягко позвать.
    if (streak == 0) return 'Начните с «Мудрости дня», и лампада загорится.';
    if (!litToday) {
      return 'Загляните в «Мудрость дня», чтобы лампада не погасла.';
    }
    if (streak == 1) {
      return 'Хорошее начало. Загляните завтра, чтобы лампада не погасла.';
    }
    // Отдельной фразы для недели нет: число дней и так видно.
    return 'Вы на верном пути. Загляните завтра, чтобы лампада горела дальше.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = progress.streakOn(today);
    final litToday = progress.isLit(today);
    final label = streakDaysLabel(streak);
    final message = _message(streak, litToday);

    return Padding(
      padding:
          AppSpacing.of(context).horizontal +
          const EdgeInsets.symmetric(vertical: 6),
      child: Semantics(
        container: true,
        label: 'Лампадка: $streak $label. $message',
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: colors.ink.withValues(alpha: isDark ? 0.07 : 0.045),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 52,
                      // Сама лампада занимает около половины холста
                      // иллюстрации, остальное прозрачное поле и свечение.
                      child: Transform.scale(
                        scale: 1.7,
                        child: Image.asset(streak > 0 ? _lampOn : _lampOff),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$streak',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  color: colors.ink,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: colors.homeSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
