import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/shell_providers.dart';

/// Высота самой капсулы.
const _barHeight = 58.0;

/// Отступ капсулы от краёв и от низа экрана.
const _sideMargin = 22.0;
const _bottomMargin = 10.0;

/// Сколько места снизу должен оставить скроллящийся контент, чтобы последний
/// элемент не оказался под капсулой. Прибавляется к нижнему padding списков.
///
const kFloatingNavInset = _barHeight + _bottomMargin + 12;

/// Плавающая навигация капсулой поверх контента.
///
/// Обычный [NavigationBar] отрезал у экрана глухую полосу снизу, и на экране,
/// где герой — один текст, это заметная потеря. Здесь контент уходит под
/// капсулу, а она сама полупрозрачная с размытием: видно, что под ней что-то
/// есть, и полоса не читается как край экрана.
///
/// Не системный Liquid Glass: Flutter рисует свой UI и нативный материал
/// iOS 26 ему недоступен — это его приближение размытием и прозрачностью.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    required this.current,
    required this.onSelect,
    super.key,
  });

  final ShellTab current;
  final void Function(ShellTab tab) onSelect;

  static const _items = [
    (
      tab: ShellTab.today,
      icon: Icons.wb_twilight_outlined,
      activeIcon: Icons.wb_twilight,
      label: 'Сегодня',
    ),
    (
      tab: ShellTab.bookmarks,
      icon: Icons.bookmark_border,
      activeIcon: Icons.bookmark,
      label: 'Закладки',
    ),
    (
      tab: ShellTab.profile,
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Профиль',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: _bottomMargin),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _sideMargin,
          0,
          _sideMargin,
          _bottomMargin,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_barHeight / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_barHeight / 2),
                // Заливка полупрозрачная: сквозь неё виден уходящий контент.
                // В тёмной теме размытие само по себе почти не читается,
                // поэтому там подложка чуть плотнее.
                color: colors.background.withValues(
                  alpha: isDark ? 0.72 : 0.62,
                ),
                border: Border.all(
                  color: colors.ink.withValues(alpha: isDark ? 0.14 : 0.07),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.ink.withValues(alpha: isDark ? 0.34 : 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SizedBox(
                height: _barHeight,
                child: Row(
                  children: [
                    for (final item in _items)
                      Expanded(
                        child: _NavItem(
                          icon: item.icon,
                          activeIcon: item.activeIcon,
                          label: item.label,
                          isSelected: item.tab == current,
                          onTap: () => onSelect(item.tab),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 20,
              color: isSelected ? colors.accent : colors.homeIcon,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                // 11pt — минимум по HIG; на 10pt подписи были мельче нормы.
                fontSize: 11,
                letterSpacing: 0.1,
                // Активная вкладка отличается акцентом и насыщенностью, а не
                // наличием подписи: без ярлыков неочевидно, куда ведут иконки.
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colors.accent : colors.homeSubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
