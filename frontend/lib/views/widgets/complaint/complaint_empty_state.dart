import 'package:flutter/material.dart';

class ComplaintEmptyState extends StatelessWidget {
  final double scale;

  const ComplaintEmptyState({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_late_outlined,
            size: 60 * scale,
            color: const Color(0xFF1A1D1F).withValues(alpha: 0.2),
          ),
          SizedBox(height: 15 * scale),
          Text(
            'No complaints found',
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1D1F),
            ),
          ),
          SizedBox(height: 5 * scale),
          Text(
            'You haven\'t submitted any complaints yet.',
            style: TextStyle(
              fontSize: 13 * scale,
              color: const Color(0xFF1A1D1F).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
