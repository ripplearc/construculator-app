import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final l10n = context.l10n;
    final width = MediaQuery.of(context).size.width;

    final iconSize = width < 360 ? 20.0 : (width <= 600 ? 24.0 : 28.0);
    final fontSize = width < 360 ? 10.0 : (width <= 600 ? 12.0 : 13.0);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: colors.textHeadline,
      unselectedItemColor: colors.textBody,
      selectedFontSize: fontSize,
      unselectedFontSize: fontSize,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: iconSize),
          activeIcon: Icon(Icons.home, size: iconSize),
          label: l10n.navHome,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calculate_outlined, size: iconSize),
          activeIcon: Icon(Icons.calculate, size: iconSize),
          label: l10n.navCalculations,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.request_quote_outlined, size: iconSize),
          activeIcon: Icon(Icons.request_quote, size: iconSize),
          label: l10n.navCostEstimation,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group_outlined, size: iconSize),
          activeIcon: Icon(Icons.group, size: iconSize),
          label: l10n.navMembers,
        ),
      ],
    );
  }
}
