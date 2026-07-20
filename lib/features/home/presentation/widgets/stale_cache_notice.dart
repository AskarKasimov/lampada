import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_link_button.dart';
import '../../../../core/widgets/app_pill_badge.dart';

/// Показан кэш за другой день. Без этой пометки юзер примет вчерашний
/// контент за сегодняшний — для приложения «карточка дня» это подлог.
class StaleCacheNotice extends StatelessWidget {
  const StaleCacheNotice({
    super.key,
    required this.staleDate,
    required this.onRefresh,
  });

  final DateTime staleDate;
  final VoidCallback onRefresh;

  static const _months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final label = 'Офлайн · карточки за '
        '${staleDate.day} ${_months[staleDate.month - 1]}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppPillBadge(
          label: label,
          background: Colors.transparent,
          foreground: colors.chipUnreadText,
          border: Border.all(color: colors.chipUnreadBorder),
          horizontalPadding: 13,
          fontSize: 11.5,
        ),
        AppLinkButton(
          label: 'Обновить',
          color: colors.link,
          fontSize: 12,
          onPressed: onRefresh,
        ),
      ],
    );
  }
}
