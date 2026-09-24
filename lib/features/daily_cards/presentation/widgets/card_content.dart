import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_pill_badge.dart';
import '../../../../core/widgets/selectable_share_area.dart';
import '../../domain/entities/day_card.dart';
import '../theme/card_type_style.dart';

/// Одна карточка дня. Вызывающий обязан передать `key: ValueKey(card.id)` —
/// иначе AnimatedSwitcher не увидит смену карточки и не сбросит скролл.
class CardContent extends StatefulWidget {
  const CardContent({
    required this.card,
    super.key,
    this.showBadge = true,
    this.scrollable = true,
  });

  final DayCard card;
  final bool showBadge;

  /// Внутри листаемой читалки вертикальный жест принадлежит переключению
  /// страниц. Длинный текст там открывается в отдельном полноэкранном виде.
  final bool scrollable;
  static const previewLength = 200;
  static final _consecutiveNewlines = RegExp(r'\n{2,}');

  /// «Основы» приходят с абзацами, разделёнными двойным переносом, который
  /// в крупной читалке создаёт избыточные пустые строки. Одиночные переносы
  /// из `<br>` сохраняем.
  static String displayBody(DayCard card) => card.type == CardType.basics
      ? card.body.replaceAll(_consecutiveNewlines, '\n')
      : card.body;

  static bool needsFullText(DayCard card) =>
      displayBody(card).length > previewLength;

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
    final hasMore =
        position.maxScrollExtent > 0 &&
        position.pixels < position.maxScrollExtent - 1;
    if (hasMore != _hasMoreBelow && mounted) {
      setState(() => _hasMoreBelow = hasMore);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final style = card.type.styleFor(Theme.of(context).brightness);
    final colors = AppColorsExtension.of(context);
    final isPreview = !widget.scrollable && CardContent.needsFullText(card);
    final displayBody = CardContent.displayBody(card);
    final body = isPreview
        ? '${displayBody.substring(0, CardContent.previewLength)}…'
        : displayBody;

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (widget.showBadge) ...[
          AppPillBadge(
            label: style.label,
            background: style.tagBackground,
            foreground: style.tagForeground,
            letterSpacing: 0.2,
          ),
          const SizedBox(height: 22),
        ],
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => widget.scrollable
                ? _scrollableContent(context, card, body, colors, constraints)
                : _previewContent(context, card, body, colors),
          ),
        ),
      ],
    );
  }

  Widget _scrollableContent(
    BuildContext context,
    DayCard card,
    String body,
    AppColorsExtension colors,
    BoxConstraints constraints,
  ) => Stack(
    children: [
      SelectableShareArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    body,
                    style: AppTheme.quoteStyle(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _sourceText(card, colors),
                ],
              ),
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
                CupertinoIcons.chevron_down,
                size: 20,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
    ],
  );

  Widget _previewContent(
    BuildContext context,
    DayCard card,
    String body,
    AppColorsExtension colors,
  ) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectableShareArea(
          child: Text(
            body,
            style: AppTheme.quoteStyle(context),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        _sourceText(card, colors),
      ],
    ),
  );

  Widget _sourceText(DayCard card, AppColorsExtension colors) =>
      Text('— ${card.source}', style: _sourceStyle(colors));

  TextStyle _sourceStyle(AppColorsExtension colors) =>
      TextStyle(fontSize: 13, letterSpacing: 0.2, color: colors.textSecondary);
}
