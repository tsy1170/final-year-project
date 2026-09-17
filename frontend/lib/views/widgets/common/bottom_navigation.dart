import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    super.key,
    required this.scale,
    required this.selectedIndex,
    required this.onTap,
  });
  final double scale;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      width: double.infinity,
      height: 60 * scale + bottomPadding,
      padding: EdgeInsets.fromLTRB(10 * scale, 0, 10 * scale, bottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFD),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFF2EFEA),
            width: 1 * scale,
          ),
        ),
      ),
      child: Row(
        children: [
          _NavItem(
            index: 0,
            selectedIndex: selectedIndex,
            label: 'Grocery',
            selectedIcon: Icons.local_grocery_store,
            unselectedIcon: Icons.local_grocery_store_outlined,
            onTap: onTap,
            scale: scale,
          ),
          _NavItem(
            index: 1,
            selectedIndex: selectedIndex,
            label: 'Favourites',
            selectedIcon: Icons.favorite_outlined,
            unselectedIcon: Icons.favorite_border,
            onTap: onTap,
            scale: scale,
          ),
          _NavItem(
            index: 2,
            selectedIndex: selectedIndex,
            label: 'Search',
            selectedIcon: Icons.search_outlined,
            unselectedIcon: Icons.search_outlined,
            onTap: onTap,
            scale: scale,
          ),
          _NavItem(
            index: 3,
            selectedIndex: selectedIndex,
            label: 'Complaints',
            selectedIcon: Icons.assignment_rounded,
            unselectedIcon: Icons.assignment_outlined,
            onTap: onTap,
            scale: scale,
          ),
          _NavItem(
            index: 4,
            selectedIndex: selectedIndex,
            label: 'Profile',
            selectedIcon: Icons.person_rounded,
            unselectedIcon: Icons.person_outline,
            onTap: onTap,
            scale: scale,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.onTap,
    required this.scale,
  });
  final int index;
  final int selectedIndex;
  final String label;
  final IconData? selectedIcon;
  final IconData? unselectedIcon;
  final ValueChanged<int> onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    final Color selectedColor = const Color(0xFF1A1D1F);
    final Color unselectedColor = Colors.black.withValues(alpha: 0.4);
    final Color itemColor = isSelected ? selectedColor : unselectedColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            HapticFeedback.lightImpact();
            onTap(index);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : unselectedIcon,
                size: 25 * scale,
                color: itemColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
