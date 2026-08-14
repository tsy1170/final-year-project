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
    return Container(
      margin: EdgeInsets.only(bottom: 12 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            width: 45 * scale,
            height: 45 * scale,
            padding: EdgeInsets.all(5 * scale),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: item['image_url'] != null
                ? Opacity(
                    opacity: 0.5,
                    child: Image.network(item['image_url'], fit: BoxFit.contain),
                  )
                : Icon(Icons.image_not_supported_outlined,
                    color: Colors.grey.withValues(alpha: 0.5), size: 18 * scale),
          ),
          SizedBox(width: 15 * scale),
          // Name and Unit
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 5 * scale),
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
          ),
        ],
      ),
    );
  }
}
