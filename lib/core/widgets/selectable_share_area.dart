import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../analytics/analytics_event.dart';
import '../analytics/analytics_provider.dart';
import '../format/app_download_links.dart';
import 'app_share_button.dart' show shareOutcomeOf;
import 'text_selection_activity.dart';

/// Делает вложенный текст выделяемым, не отнимая горизонтальные свайпы у
/// PageView на Android.
class SelectableShareArea extends ConsumerStatefulWidget {
  const SelectableShareArea({required this.child, super.key, this.content});

  final Widget child;

  /// Тип материала для аналитики; null — отправку не считаем.
  final SharedContent? content;

  @override
  ConsumerState<SelectableShareArea> createState() =>
      _SelectableShareAreaState();
}

class _SelectableShareAreaState extends ConsumerState<SelectableShareArea> {
  final _selectionAreaKey = GlobalKey<SelectionAreaState>();
  SelectedContent? _selectedContent;
  var _selectionEnabled = false;

  Future<void> _enableSelection() async {
    if (_selectionEnabled) return;
    const TextSelectionActivity(active: true).dispatch(context);
    setState(() => _selectionEnabled = true);
    // Сначала монтируется SelectionArea, затем вложенные scroll/selection
    // контейнеры регистрируют текст. До конца этих кадров selectAll пуст.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _selectionAreaKey.currentState?.selectableRegion.selectAll(
      SelectionChangedCause.toolbar,
    );
  }

  void _onSelectionChanged(SelectedContent? content) {
    final hasSelection = content != null;
    if (_selectedContent?.plainText == content?.plainText &&
        _selectionEnabled == hasSelection) {
      return;
    }
    setState(() {
      _selectedContent = content;
      _selectionEnabled = hasSelection;
    });
    TextSelectionActivity(active: hasSelection).dispatch(context);
  }

  Widget _buildContextMenu(
    BuildContext context,
    SelectableRegionState selectableRegionState,
  ) {
    final buttonItems = [
      for (final item in selectableRegionState.contextMenuButtonItems)
        _russianButtonItem(item),
    ];
    buttonItems.add(
      ContextMenuButtonItem(
        label: 'Поделиться',
        onPressed: () {
          final text = _selectedContent?.plainText;
          if (text == null || text.isEmpty) return;
          _shareSelectedText(context, selectableRegionState, text);
        },
      ),
    );
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: selectableRegionState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  ContextMenuButtonItem _russianButtonItem(ContextMenuButtonItem item) {
    return switch (item.type) {
      ContextMenuButtonType.copy => item.copyWith(label: 'Копировать'),
      ContextMenuButtonType.selectAll => item.copyWith(label: 'Выбрать всё'),
      _ => item,
    };
  }

  Future<void> _shareSelectedText(
    BuildContext context,
    SelectableRegionState selectableRegionState,
    String text,
  ) async {
    selectableRegionState.hideToolbar();
    final box = context.findRenderObject()! as RenderBox;
    final analytics = ref.read(analyticsProvider);
    final result = await SharePlus.instance.share(
      ShareParams(
        text: appendAppDownloadLinks(text),
        // На iPad лист отправки открывается поповером; задаём его источник.
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      ),
    );
    final content = widget.content;
    if (content == null) return;
    analytics.log(
      AnalyticsEvent.contentShared(
        content: content,
        method: ShareMethod.selection,
        result: shareOutcomeOf(result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_selectionEnabled) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: _enableSelection,
        child: widget.child,
      );
    }
    return SelectionArea(
      key: _selectionAreaKey,
      contextMenuBuilder: _buildContextMenu,
      onSelectionChanged: _onSelectionChanged,
      child: widget.child,
    );
  }
}
