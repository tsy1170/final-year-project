import 'package:flutter/material.dart';

class FavouriteEmptyState extends StatelessWidget {
  final double scale;

  const FavouriteEmptyState({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 60 * scale,
            color: const Color(0xFF1A1D1F).withValues(alpha: 0.2),
          ),
          SizedBox(height: 15 * scale),
          Text(
            'Your list is empty',
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1D1F),
            ),
          ),
          SizedBox(height: 5 * scale),
        ],
      ),
    );
  }
}
