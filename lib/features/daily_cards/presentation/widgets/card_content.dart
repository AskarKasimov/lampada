import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/day_card.dart';
import '../theme/card_type_style.dart';

/// Одна карточка дня: плашка-тип (pinned, не скроллится), курсивная мысль
/// (скроллится, если не помещается — короткий текст остаётся по центру
/// как раньше) и источник. Вызывающий обязан передать
/// `key: ValueKey(card.id)` — иначе AnimatedSwitcher не увидит смену
/// карточки, а скролл предыдущей карточки не сбросится на новую.
class CardContent extends StatefulWidget {
  const CardContent({super.key, required this.card});

  final DayCard card;

  @override
  State<CardContent> createState() => _CardContentState();
}

class _CardContentState extends State<CardContent> {
  final _scrollController = ScrollController();
  bool _hasMoreBelow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateHasMoreBelow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHasMoreBelow());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateHasMoreBelow);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateHasMoreBelow() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final hasMore = position.maxScrollExtent > 0 &&
        position.pixels < position.maxScrollExtent - 1;
    if (hasMore != _hasMoreBelow && mounted) {
      setState(() => _hasMoreBelow = hasMore);
    }
  }

  /// Короткий текст (цитата/притча) держит крупный шрифт как раньше;
  /// длинный реальный контент с azbyka.ru (совет/основы) читается мельче,
  /// чтобы меньше скроллить.
  static double _fontSizeFor(int bodyLength) {
    if (bodyLength <= 220) return 24;
    if (bodyLength <= 500) return 21;
    return 18;
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final style = card.type.styleFor(Theme.of(context).brightness);
    final colors = AppColorsExtension.of(context);
    final fontSize = _fontSizeFor(card.body.length);

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: style.tagBackground,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            style.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: style.tagForeground,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            card.body,
                            style: AppTheme.quoteStyle(context)
                                .copyWith(fontSize: fontSize),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '— ${card.source}',
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 0.2,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_hasMoreBelow)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 36,
                        alignment: Alignment.bottomCenter,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colors.background.withValues(alpha: 0),
                              colors.background,
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
