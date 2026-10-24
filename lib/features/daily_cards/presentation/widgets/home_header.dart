import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import 'frosted_fade.dart';
import 'streak_card.dart';
import 'streak_lamp_icon.dart';

/// Приветствие по времени суток. Отдельной ночи нет: «Доброй ночи»
/// по-русски прощание, поэтому до 4 утра продолжается вечер.
String greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour >= 4 && hour < 12) return 'Доброе утро!';
  if (hour >= 12 && hour < 18) return 'Добрый день!';
  return 'Добрый вечер!';
}

/// Шапка главной: приветствие и лампада серии, которая открывает шторку
/// «Лампадки». Даты и поста в шапке нет.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.now,
    required this.streak,
    required this.onStreakTap,
    super.key,
  });

  final DateTime now;

  /// Текущая серия; null, пока прогресс не загружен.
  final int? streak;

  final VoidCallback onStreakTap;

  @override
  Widget build(BuildContext context) {
    final streak = this.streak;
    return Padding(
      padding:
          AppSpacing.of(context).horizontal +
          const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                greetingFor(now),
                style: AppTheme.headingStyle(context, fontSize: 30),
              ),
            ),
          ),
          if (streak != null) ...[
            const SizedBox(width: 8),
            _StreakButton(streak: streak, onTap: onStreakTap),
          ],
        ],
      ),
    );
  }
}

/// Подложка закреплённой шапки, под которую уходит список. Матовое стекло
/// цвета фона, а ниже зона растворения ([FrostedFade]), где размытие и
/// подложка плавно сходят на нет. Так у шапки нет чёткой границы, о
/// которую обрезался бы контент.
class FrostedHomeHeader extends StatelessWidget {
  const FrostedHomeHeader({required this.child, super.key});

  final Widget child;

  static const _blur = 12.0;
  static const _tint = 0.82;

  @override
  Widget build(BuildContext context) {
    final background = AppColorsExtension.of(context).background;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background.withValues(alpha: _tint),
              ),
              child: child,
            ),
          ),
        ),
        FrostedFade(
          color: background.withValues(alpha: _tint),
          blur: _blur,
          fadesDown: true,
        ),
      ],
    );
  }
}

class _StreakButton extends StatelessWidget {
  const _StreakButton({required this.streak, required this.onTap});

  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Semantics(
      button: true,
      label: 'Лампадка: $streak ${streakDaysLabel(streak)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(22),
        child: ConstrainedBox(
          // Минимальная зона нажатия по HIG.
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreakLampIcon(lit: streak > 0, size: 28),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: streak > 0 ? colors.ink : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
