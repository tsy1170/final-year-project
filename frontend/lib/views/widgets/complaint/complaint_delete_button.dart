import 'package:flutter/material.dart';

class ComplaintDeleteButton extends StatelessWidget {
  final double scale;
  final int itemCount;
  final VoidCallback onDeletePressed;

  const ComplaintDeleteButton({
    super.key,
    required this.scale,
    required this.itemCount,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final double navBarHeight = MediaQuery.of(context).padding.bottom;
    
    return Positioned(
      left: 0,
      right: 0,
      bottom: 60 * scale + navBarHeight,
      child: Container(
        width: double.infinity,
        height: 60 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFFB85A3A),
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.3),
              width: 1 * scale,
            ),
          )
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onDeletePressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$itemCount SELECTED',
                    style: TextStyle(
                      color: const Color(0xFFFFFDFD),
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'DELETE ',
                        style: TextStyle(
                          color: const Color(0xFFFFFDFD),
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Icon(
                        Icons.delete_outline_rounded,
                        color: const Color(0xFFFFFDFD),
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
