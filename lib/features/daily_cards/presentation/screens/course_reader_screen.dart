import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../domain/entities/day_card.dart';
import '../providers/providers.dart';
import '../theme/card_type_style.dart';
import '../widgets/card_content.dart';

/// Полноэкранное чтение личного курса «Основы веры».
///
/// Нулевая страница — текущая тема. Движение влево открывает только уже
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
                itemCount: _currentTopicNumber,
                onPageChanged: (page) => setState(() => _index = page),
                itemBuilder: (context, page) {
                  final card = _cardForPage(page);
                  if (card == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return CardContent(key: ValueKey(card.id), card: card);
                },
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
