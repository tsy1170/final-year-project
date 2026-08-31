import 'package:flutter/material.dart';

class OptimizationItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final double scale;

  const OptimizationItemRow({
    super.key,
    required this.item,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 15 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start, // Align top
        children: [
          // Image
          Container(
            width: 55 * scale,
            height: 55 * scale,
            padding: EdgeInsets.all(2 * scale),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: item['image_url'] != null
                ? Image.network(
                    item['image_url'],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image_not_supported_outlined, size: 20 * scale),
                  )
                : Icon(Icons.image_outlined, color: Colors.grey, size: 20 * scale),
          ),
          SizedBox(width: 15 * scale),
          // Name and Unit
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    item['item_name'] ?? '',
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D1F),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['unit'] ?? '',
                    style: TextStyle(
                      fontSize: 11 * scale,
                      color: Color(0xFF1A1D1F).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(width: 10 * scale),
          // Price
          Padding(
            padding: EdgeInsets.only(top: 5 * scale),
            child: Text(
              'RM ${item['price']?.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1D1F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
