import 'package:flutter/material.dart';

class CustomBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final double scale;
  final double? height;

  const CustomBottomSheet({
    super.key,
    required this.title,
    required this.child,
    required this.scale,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20 * scale)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1 * scale,
                ),
              ),
              color: const Color(0xFF1A1D1F),
            ),
            child: Column(
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      150 * scale,
                      11 * scale,
                      150 * scale,
                      0,
                    ),
                    child: Container(
                      height: 4 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDFD),
                        borderRadius: BorderRadius.circular(15 * scale),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 25 * scale,
                    horizontal: 20 * scale,
                  ),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFFDFD),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
