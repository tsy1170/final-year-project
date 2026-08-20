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
      // The height is the standard height plus the safe area padding
      height: 70 * scale + bottomPadding,
      // Padding bottom ensures the icons don't overlap with the system gesture bar
      padding: EdgeInsets.fromLTRB(24 * scale, 0, 24 * scale, bottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFD),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1 * scale
          )
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            index: 0,
            selectedIndex: selectedIndex,
            label: 'GROCERY',
            icon: Icons.local_grocery_store_outlined,
            onTap: onTap,
            scale: scale,
          ),
          _NavItem(
            index: 1,
            selectedIndex: selectedIndex,
            label: 'FAVOURITES',
            icon: Icons.favorite_border,
            onTap: onTap,
            scale: scale,
          ),
          _NavItem(
            index: 2,
            selectedIndex: selectedIndex,
            label: 'COMPLAINT',
            icon: Icons.assignment_outlined,
            onTap: onTap,
            scale: scale,
          ),
          _NavItem(
            index: 3,
            selectedIndex: selectedIndex,
            label: 'PROFILE',
            icon: Icons.person_outline,
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
    required this.icon,
    required this.onTap,
    required this.scale,
  });
  final int index;
  final int selectedIndex;
  final String label;
  final IconData? icon;
  final ValueChanged<int> onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.lightImpact(); // Add physical feel
          onTap(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 * scale : 12 * scale,
          vertical: 8 * scale,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1D1F) : Colors.transparent,
          borderRadius: BorderRadius.circular(25 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24 * scale,
              color: isSelected ? const Color(0xFFFFFDFD) : const Color(0xFF1A1D1F),
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: SizedBox(
                  width: isSelected ? null : 0,
                  child: isSelected
                      ? Padding(
                    padding: EdgeInsets.only(left: 8 * scale),
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: const Color(0xFFFFFDFD),
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
