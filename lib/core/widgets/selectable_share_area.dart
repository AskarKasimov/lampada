import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:share_plus/share_plus.dart';

import '../format/app_download_links.dart';

/// Делает вложенный текст выделяемым, не отнимая горизонтальные свайпы у
/// PageView на Android.
class SelectableShareArea extends StatefulWidget {
  const SelectableShareArea({required this.child, super.key});

  final Widget child;

  @override
  State<SelectableShareArea> createState() => _SelectableShareAreaState();
}

class _SelectableShareAreaState extends State<SelectableShareArea> {
  final _selectionAreaKey = GlobalKey<SelectionAreaState>();
  SelectedContent? _selectedContent;
  var _selectionEnabled = false;

  void _enableSelection() {
    if (_selectionEnabled) return;
    setState(() => _selectionEnabled = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _selectionAreaKey.currentState?.selectableRegion.selectAll(
        SelectionChangedCause.toolbar,
      );
    });
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
    await SharePlus.instance.share(
      ShareParams(
        text: appendAppDownloadLinks(text),
        // На iPad лист отправки открывается поповером; задаём его источник.
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
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
