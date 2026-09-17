import 'package:flutter/material.dart';

class OptimizationSubHeader extends StatelessWidget {
  final double scale;
  final bool isSingleStore;
  final VoidCallback onSingleStoreTap;
  final VoidCallback onMultiStoreTap;

  const OptimizationSubHeader({
    super.key,
    required this.scale,
    required this.isSingleStore,
    required this.onSingleStoreTap,
    required this.onMultiStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFBF8F5),
      padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 10 * scale),
      child: Container(
        height: 45 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EDE7), // Soft neutral background for the track
          borderRadius: BorderRadius.circular(25 * scale),
        ),
        child: Stack(
          children: [
            // Animated Sliding Pill
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              alignment: isSingleStore ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  margin: EdgeInsets.all(4 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB85A3A),
                    borderRadius: BorderRadius.circular(21 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB85A3A).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onSingleStoreTap,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Text(
                        'Single-Store',
                        style: TextStyle(
                          color: isSingleStore 
                              ? Colors.white 
                              : const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: onMultiStoreTap,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Text(
                        'Multi-Store',
                        style: TextStyle(
                          color: !isSingleStore 
                              ? Colors.white 
                              : const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
