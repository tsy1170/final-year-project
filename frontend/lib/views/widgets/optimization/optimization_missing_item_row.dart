import 'package:flutter/material.dart';

class OptimizationMissingItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final double scale;

  const OptimizationMissingItemRow({
    super.key,
    required this.item,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final itemCode = item['item_code'];
    return Container(
      margin: EdgeInsets.only(bottom: 12 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder straight from assets/product_images/ folder with item code
          Container(
            width: 45 * scale,
            height: 45 * scale,
            padding: EdgeInsets.all(2 * scale),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: itemCode != null
                ? Opacity(
                    opacity: 0.5,
                    child: Image.asset(
                      'assets/product_images/$itemCode.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/product_images/$itemCode.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey.withValues(alpha: 0.5),
                          size: 18 * scale,
                        ),
                      ),
                    ),
                  )
                : Icon(Icons.image_not_supported_outlined,
                    color: Colors.grey.withValues(alpha: 0.5), size: 18 * scale),
          ),
          SizedBox(width: 15 * scale),
          // Name and Unit
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['item_name'] ?? '',
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    item['unit'] ?? '',
                    style: TextStyle(
                      fontSize: 10 * scale,
                      color: const Color(0xFF9A9FA5),
                    ),
                  ),
                ],
              ),
            ),

        ],
      ),
    );
  }
}
