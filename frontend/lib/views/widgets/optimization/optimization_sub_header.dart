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
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      height: 50 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF3),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1 * scale,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Animated Sliding Indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            bottom: 0,
            left: isSingleStore ? 0 : screenWidth / 2,
            child: Container(
              width: screenWidth / 2,
              height: 3 * scale,
              color: const Color(0xFF325E6A),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onSingleStoreTap,
                  style: TextButton.styleFrom(
                    shape: const RoundedRectangleBorder(),
                    overlayColor: Colors.grey,
                    minimumSize: const Size(double.infinity, double.infinity),
                  ),
                  child: Text(
                    'SINGLE-STORE',
                    style: TextStyle(
                      color: isSingleStore
                          ? const Color(0xFF325E6A)
                          : const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: onMultiStoreTap,
                  style: TextButton.styleFrom(
                    shape: const RoundedRectangleBorder(),
                    overlayColor: Colors.grey,
                    minimumSize: const Size(double.infinity, double.infinity),
                  ),
                  child: Text(
                    'MULTI-STORE',
                    style: TextStyle(
                      color: !isSingleStore
                          ? const Color(0xFF325E6A)
                          : const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
