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
const kFloatingNavWithHeaderInset = kFloatingNavInset + 90;

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
    this.header,
    super.key,
  });

  final ShellTab current;
  final void Function(ShellTab tab) onSelect;
  final Widget? header;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ?header,
                  SizedBox(
                    height: _barHeight,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = constraints.maxWidth / _items.length;
                        return Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              left: itemWidth * current.index + 4,
                              top: 4,
                              width: itemWidth - 8,
                              height: _barHeight - 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.background.withValues(
                                    alpha: isDark ? 0.42 : 0.48,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: colors.ink.withValues(
                                      alpha: isDark ? 0.20 : 0.10,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.background.withValues(
                                        alpha: isDark ? 0.16 : 0.34,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
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
                          ],
                        );
                      },
                    ),
                  ),
                ],
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
        child: _NavItemContent(
          icon: isSelected ? activeIcon : icon,
          label: label,
          color: isSelected ? colors.accent : colors.homeIcon,
          isSelected: isSelected,
        ),
      ),
    );
  }
}

class _NavItemContent extends StatelessWidget {
  const _NavItemContent({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            // 11pt — минимум по HIG; на 10pt подписи были мельче нормы.
            fontSize: 11,
            letterSpacing: 0.1,
            // Активную вкладку отличают акцент и лёгкая стеклянная рамка,
            // но подписи остаются у всех — так переходы понятны сразу.
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? color : colors.homeSubtitle,
          ),
        ),
      ],
    );
  }
}
