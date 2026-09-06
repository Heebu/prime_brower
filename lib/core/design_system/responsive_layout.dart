import 'package:flutter/material.dart';

enum ScreenType {
  compact,   // < 600dp (standard mobile phones)
  medium,    // 600dp - 839dp (foldables, vertical tablets)
  expanded,  // >= 840dp (tablets in landscape, desktop windows)
}

class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context) compact;
  final Widget Function(BuildContext context)? medium;
  final Widget Function(BuildContext context)? expanded;

  const ResponsiveLayout({
    Key? key,
    required this.compact,
    this.medium,
    this.expanded,
  }) : super(key: key);

  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return ScreenType.compact;
    if (width < 840) return ScreenType.medium;
    return ScreenType.expanded;
  }

  static bool isCompact(BuildContext context) =>
      getScreenType(context) == ScreenType.compact;

  static bool isMedium(BuildContext context) =>
      getScreenType(context) == ScreenType.medium;

  static bool isExpanded(BuildContext context) =>
      getScreenType(context) == ScreenType.expanded;

  static bool isTabletOrLarger(BuildContext context) =>
      getScreenType(context) != ScreenType.compact;

  /// Determines optimal grid column count for Tab Grid Switcher
  static int getTabGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final screenType = getScreenType(context);

    if (screenType == ScreenType.expanded && expanded != null) {
      return expanded!(context);
    }
    if (screenType == ScreenType.medium && medium != null) {
      return medium!(context);
    }
    return compact(context);
  }
}
