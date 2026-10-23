import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/today_cards.dart';
import 'home_grid_tile.dart';
import 'read_status_checks.dart';

/// Память дня на главной: икона на всю плитку и подпись «Память дня»
/// сверху. Имя святого на плитке не пишем: длинные имена не помещались в
/// половину ширины, а икона сама говорит, чья память.
///
/// Адрес иконы передаёт загрузчик содержимого дня. Без иконы, и если она не
/// загрузилась, плитка не пустая: на ней имя святого.
class DayMemoryTile extends StatelessWidget {
  const DayMemoryTile({
    required this.day,
    this.iconUrl,
    this.onTap,
    this.isRead = false,
    super.key,
  });

  final TodayCards day;
  final String? iconUrl;

  /// Открывает рассказ. Без ссылки на рассказ плитка не нажимается.
  final VoidCallback? onTap;

  /// Рассказ дня уже открывали: отметка как у «Мудрости дня».
  final bool isRead;

  /// Розовый свободен на главной: «Мудрость» янтарная, курс зелёный.
  static const _type = CardType.reading;

  @override
  Widget build(BuildContext context) {
    final title = day.title!.trim();
    final iconUrl = this.iconUrl;
    return HomeGridTile(
      title: 'Память дня',
      type: _type,
      semanticsLabel: 'Память дня: $title${isRead ? '. Прочитано' : ''}',
      titleTrailing: ReadStatusChecks(isUnread: !isRead),
      onTap: day.storyUrl == null ? null : onTap,
      background: (_) => iconUrl == null
          ? _NameFallback(name: title)
          : Image.network(
              iconUrl,
              fit: BoxFit.cover,
              // Лик в верхней части иконы, подпись внизу его не закрывает.
              alignment: Alignment.topCenter,
              excludeFromSemantics: true,
              // Пока икона грузится, видна спокойная заливка плитки.
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const SizedBox.shrink(),
              errorBuilder: (context, error, stackTrace) =>
                  _NameFallback(name: title),
            ),
    );
  }
}

/// Имя святого вверху плитки, когда иконы нет: низ занят подписью.
class _NameFallback extends StatelessWidget {
  const _NameFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
      child: Text(
        name,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.cardTitleStyle(context),
      ),
    ),
  );
}
