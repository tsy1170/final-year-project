import 'package:flutter/material.dart';

class OptimizationHeader extends StatelessWidget {
  final double scale;

  const OptimizationHeader({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60 * scale,
      padding: EdgeInsets.symmetric(horizontal: 10 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFD),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1 * scale,
          ),
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 22 * scale,
                color: const Color(0xFF1A1D1F),
              ),
            ),
          ),
          Center(
            child: Text(
              'COMPARE',
              style: TextStyle(
                color: const Color(0xFF1A1D1F),
                fontSize: 18 * scale,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
