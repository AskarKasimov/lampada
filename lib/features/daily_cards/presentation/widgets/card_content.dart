import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/reading_font_size.dart';
import '../../../../core/theme/reading_text_layout.dart';
import '../../../../core/widgets/app_pill_badge.dart';
import '../../../../core/widgets/reading_action_space.dart';
import '../../../../core/widgets/reading_overflow_listener.dart';
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
    this.showSourceDash = true,
    this.showSource = true,
    this.scrollable = true,
    this.scrollController,
  });

  final DayCard card;
  final bool showBadge;
  final bool showSourceDash;
  final bool showSource;

  /// Внутри листаемой читалки вертикальный жест принадлежит переключению
  /// страниц. Длинный текст там открывается в отдельном полноэкранном виде.
  final bool scrollable;

  /// Внешний контроллер нужен полноэкранному тексту, чтобы различать его
  /// прокрутку и жест закрытия на границах материала.
  final ScrollController? scrollController;

  @override
  State<CardContent> createState() => _CardContentState();
}

class _CardContentState extends State<CardContent> {
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;
  bool _hasMoreBelow = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _ownsScrollController = widget.scrollController == null;
    _scrollController.addListener(_updateHasMoreBelow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHasMoreBelow());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateHasMoreBelow);
    if (_ownsScrollController) _scrollController.dispose();
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
            builder: (context, constraints) {
              final availableHeight =
                  constraints.maxHeight -
                  (widget.scrollable ? 0 : ReadingActionSpace.of(context));
              final baseStyle = _bodyStyle(context, card);
              final sourceHeight = widget.showSource
                  ? 16 +
                        readingTextHeight(
                          context: context,
                          text:
                              '${widget.showSourceDash ? '— ' : ''}${card.source}',
                          style: _sourceStyle(colors),
                          maxWidth: constraints.maxWidth,
                        )
                  : 0.0;
              final scaledSourceHeight = widget.showSource
                  ? 16 +
                        readingTextHeight(
                          context: context,
                          text:
                              '${widget.showSourceDash ? '— ' : ''}${card.source}',
                          style: _sourceStyle(colors),
                          maxWidth: constraints.maxWidth,
                          textScaler: MediaQuery.textScalerOf(context),
                        )
                  : 0.0;
              final layout = widget.scrollable
                  ? null
                  : readingTextLayout(
                      context: context,
                      text: card.body,
                      style: baseStyle,
                      maxWidth: constraints.maxWidth,
                      maxHeight: availableHeight - sourceHeight,
                      scaledMaxHeight: availableHeight - scaledSourceHeight,
                      previewExtraHeight: ReadingActionSpace.extraForPreview(
                        context,
                      ),
                    );
              final body = layout?.text ?? card.body;
              final bodyStyle = baseStyle.copyWith(
                fontSize:
                    layout?.fontSize ??
                    readingFontSize(
                      context: context,
                      text: body,
                      style: baseStyle,
                      maxWidth: constraints.maxWidth,
                      maxHeight: availableHeight - sourceHeight,
                    ),
              );
              if (layout != null) {
                ReadingOverflowListener.report(context, layout.needsFullText);
              }
              return widget.scrollable
                  ? _scrollableContent(
                      context,
                      card,
                      body,
                      colors,
                      constraints,
                      bodyStyle,
                    )
                  : _previewContent(
                      context,
                      card,
                      body,
                      colors,
                      bodyStyle,
                      layout!.needsFullText,
                    );
            },
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
    TextStyle bodyStyle,
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
                  Text(body, style: bodyStyle, textAlign: TextAlign.center),
                  if (widget.showSource) ...[
                    const SizedBox(height: 16),
                    _sourceText(card, colors),
                  ],
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
    TextStyle bodyStyle,
    bool needsFullText,
  ) => ReadingContentPosition(
    needsFullText: needsFullText,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectableShareArea(
          child: Text(body, style: bodyStyle, textAlign: TextAlign.center),
        ),
        if (widget.showSource) ...[
          const SizedBox(height: 16),
          _sourceText(card, colors),
        ],
      ],
    ),
  );

  Widget _sourceText(DayCard card, AppColorsExtension colors) => Text(
    '${widget.showSourceDash ? '— ' : ''}${card.source}',
    style: _sourceStyle(colors),
  );

  TextStyle _bodyStyle(BuildContext context, DayCard card) =>
      card.type == CardType.reading
      ? AppTheme.readingTextStyle(context)
      : AppTheme.quoteStyle(context);

  TextStyle _sourceStyle(AppColorsExtension colors) =>
      TextStyle(fontSize: 13, letterSpacing: 0.2, color: colors.textSecondary);
}
