import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_pill_badge.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../domain/entities/daily_reading.dart';

/// Толкование к стиху, поднятое шитом снизу.
///
/// Шит, а не отдельный маршрут: юзер остаётся на стихе, к которому читает
/// толкование, и закрывает его тем же движением, каким открыл. Карточкой
/// в конце отрывка эта мысль стояла через десяток экранов от своего стиха.
///
/// Текст святоотеческий и плотный — это зафиксированная граница MVP, а не
/// недоработка: авторский пересказ «на пальцах» вынесен в бэклог. Поэтому
/// кегль тут мельче стиха и колонка выровнена по левому краю: по центру
/// простыня на несколько экранов нечитаема.
class InterpretationSheet extends StatelessWidget {
  const InterpretationSheet({
    super.key,
    required this.verse,
    required this.author,
  });

  final Verse verse;
  final String? author;

  static Future<void> show(
    BuildContext context, {
    required Verse verse,
    required String? author,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: AppColorsExtension.of(context).background,
        builder: (_) => InterpretationSheet(verse: verse, author: author),
      );

  /// savedAt — заглушка, момент сохранения ставит сама кнопка.
  Bookmark get _bookmark => Bookmark(
        id: 'interpretation-${verse.interpretationRange}',
        kind: BookmarkKind.interpretation,
        text: verse.interpretation ?? '',
        source: author ?? verse.interpretationRange ?? '',
        label: 'Толкование',
        savedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return SafeArea(
      // Не на весь экран: видно, что под шитом остался стих.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppPillBadge(
                    label: 'Толкование',
                    background: Colors.transparent,
                    foreground: colors.chipUnreadText,
                    border: Border.all(color: colors.chipUnreadBorder),
                    horizontalPadding: 13,
                    fontSize: 11.5,
                  ),
                  const Spacer(),
                  BookmarkButton(bookmark: _bookmark),
                ],
              ),
              if (verse.interpretationRange != null) ...[
                const SizedBox(height: 8),
                // Один блок часто написан на несколько стихов — говорим,
                // на какие, чтобы не выдавать общее толкование за частное.
                Text(
                  'на ${verse.interpretationRange}',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verse.interpretation ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: colors.ink,
                        ),
                      ),
                      if (author != null && author!.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          '— $author',
                          style: TextStyle(
                            fontSize: 13,
                            letterSpacing: 0.2,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
