import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_link_button.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../domain/entities/day_card.dart';
import '../providers/providers.dart';
import '../theme/card_type_style.dart';
import '../widgets/card_content.dart';

/// Полноэкранное чтение личного курса «Основы веры».
///
/// Нулевая страница — текущая тема. Движение вправо открывает только уже
/// пройденные темы, поэтому будущие части курса здесь недоступны.
class CourseReaderScreen extends ConsumerStatefulWidget {
  const CourseReaderScreen({super.key, required this.currentTopic});

  final DayCard currentTopic;

  @override
  ConsumerState<CourseReaderScreen> createState() => _CourseReaderScreenState();
}

class _CourseReaderScreenState extends ConsumerState<CourseReaderScreen> {
  late final int _currentTopicNumber = _topicNumber(widget.currentTopic.id);
  final _controller = PageController();
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _markCurrentTopicRead();
    if (_currentTopicNumber > 1) {
      // Запускаем загрузку первой исторической страницы до жеста пользователя.
      ref.read(courseTopicByNumberProvider(_currentTopicNumber - 1));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _markCurrentTopicRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(dayProgressProvider.notifier).markRead(CardType.basics);
      }
    });
  }

  int _topicForPage(int page) => _currentTopicNumber - page;

  DayCard? _cardForPage(int page) {
    if (page == 0) return widget.currentTopic;
    return ref.watch(courseTopicByNumberProvider(_topicForPage(page))).value;
  }

  Widget _contentForPage(int page, AppColorsExtension colors) {
    if (page == 0) {
      return CardContent(
        key: ValueKey(widget.currentTopic.id),
        card: widget.currentTopic,
      );
    }

    final topic = _topicForPage(page);
    return ref
        .watch(courseTopicByNumberProvider(topic))
        .when(
          data: (card) => CardContent(key: ValueKey(card.id), card: card),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Тема недоступна',
                  style: TextStyle(fontSize: 14, color: colors.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  'Не удалось загрузить эту тему',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.homeSubtitle),
                ),
                const SizedBox(height: 12),
                AppLinkButton(
                  label: 'Повторить',
                  color: colors.link,
                  fontSize: 12,
                  onPressed: () =>
                      ref.invalidate(courseTopicByNumberProvider(topic)),
                ),
              ],
            ),
          ),
        );
  }

  Bookmark _bookmarkFor(DayCard card, Brightness brightness) => Bookmark(
    id: card.id,
    kind: BookmarkKind.card,
    text: card.body,
    source: card.source,
    label: card.type.styleFor(brightness).label,
    savedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final brightness = Theme.of(context).brightness;
    final currentCard = _cardForPage(_index);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 48, 34, 24),
              child: PageView.builder(
                controller: _controller,
                reverse: true,
                itemCount: _currentTopicNumber,
                onPageChanged: (page) => setState(() => _index = page),
                itemBuilder: (context, page) => _contentForPage(page, colors),
              ),
            ),
            Positioned(
              top: 0,
              left: 8,
              child: currentCard == null
                  ? const SizedBox.square(dimension: 40)
                  : BookmarkButton(
                      bookmark: _bookmarkFor(currentCard, brightness),
                    ),
            ),
            Positioned(
              top: 11,
              left: 56,
              right: 56,
              child: Text(
                'Основы веры',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.ink),
              ),
            ),
            Positioned(
              top: 0,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                color: colors.homeIcon,
                tooltip: 'Закрыть',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _topicNumber(String id) {
  final match = RegExp(r'^basics-topic-(\d+)$').firstMatch(id);
  return int.tryParse(match?.group(1) ?? '') ?? 1;
}
