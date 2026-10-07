import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/day_card.dart';
import '../theme/card_type_style.dart';

/// Крупная цветная плитка входа на главной.
///
/// «Мудрость дня» и «Основы веры» собраны на ней одинаково: только заголовок,
/// цвет типа материала и декоративная иллюстрация. Подробности открываются внутри.
class HomeTile extends StatelessWidget {
  const HomeTile({
    required this.title,
    required this.type,
    required this.illustration,
    required this.semanticsLabel,
    required this.onTap,
    this.status,
    this.action,
    this.progress,
    this.progressLabel,
    super.key,
  });

  final String title;

  /// Цвета плитки берутся из стиля этого типа карточки.
  final CardType type;

  /// Декоративная иллюстрация справа; цвет задаёт плитка.
  final Widget Function(Color color) illustration;
  final String semanticsLabel;

  /// `null` выключает нажатие, например пока материалы дня грузятся.
  final VoidCallback? onTap;

  /// Отметка прочтения или индикатор загрузки над заголовком.
  final Widget? status;

  /// Небольшая кнопка в правом верхнем углу.
  final Widget? action;

  /// Доля пройденного: показывается полосой, без текста.
  final double? progress;

  /// Короткий счётчик справа от полосы, например «7/365».
  final String? progressLabel;

  static const _radius = 24.0;
  static const _minHeight = 136.0;

  /// Узкий заголовок переносится на две строки, как на плитках-обложках,
  /// и не наезжает на значок справа.
  static const _titleMaxWidth = 170.0;

  @override
  Widget build(BuildContext context) {
    final style = type.styleFor(Theme.of(context).brightness);
    final progress = this.progress;
    return Padding(
      padding:
          AppSpacing.of(context).horizontal +
          const EdgeInsets.symmetric(vertical: 6),
      child: Semantics(
        container: true,
        button: true,
        enabled: onTap != null,
        label: semanticsLabel,
        child: Material(
          color: style.tagBackground,
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              // Плитка всегда во всю ширину, даже в Column без stretch.
              constraints: const BoxConstraints(
                minWidth: double.infinity,
                minHeight: _minHeight,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -28,
                    child: ExcludeSemantics(
                      child: illustration(style.accent.withValues(alpha: 0.22)),
                    ),
                  ),
                  // Всё нужное скринридеру уже в подписи плитки.
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 14, child: status),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _titleMaxWidth,
                            ),
                            child: Text(
                              title,
                              style: AppTheme.quoteStyle(context).copyWith(
                                fontSize: 30,
                                height: 1.15,
                                color: style.tagForeground,
                              ),
                            ),
                          ),
                          if (progress != null) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      color: style.accent,
                                      backgroundColor: style.accent.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                if (progressLabel case final label?) ...[
                                  const SizedBox(width: 10),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: style.tagForeground.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (action case final action?)
                    Positioned(top: 4, right: 4, child: action),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
