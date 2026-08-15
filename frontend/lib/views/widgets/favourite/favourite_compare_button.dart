import 'package:flutter/material.dart';
import '../../optimization_view.dart';

class FavouriteCompareButton extends StatelessWidget {
  final double scale;
  final int itemCount;

  const FavouriteCompareButton({
    super.key,
    required this.scale,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final double navBarHeight = MediaQuery.of(context).padding.bottom;
    
    return Positioned(
      left: 0,
      right: 0,
      bottom: 70 * scale + navBarHeight,
      child: Container(
        width: double.infinity,
        height: 60 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFFED1A4B),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10 * scale,
              offset: Offset(0, -5 * scale),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OptimizationView(scale: scale),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$itemCount ITEMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'COMPARE ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20 * scale,
                      ),
                    ],
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
