import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/price_alert.dart';
import '../../grocery/product_details_view.dart';

class PriceAlertCard extends StatelessWidget {
  final PriceAlert alert;
  final double scale;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isFirst;
  final bool isLast;

  const PriceAlertCard({
    super.key,
    required this.alert,
    required this.scale,
    this.onEdit,
    this.onDelete,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? Radius.circular(20 * scale) : Radius.zero,
          bottom: isLast ? Radius.circular(20 * scale) : Radius.zero,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailsView(itemCode: alert.itemCode, scale: scale),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16 * scale),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grounded Image Thumbnail
                Container(
                  width: 80 * scale,
                  height: 80 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white, // Soft warm background stage
                    borderRadius: BorderRadius.circular(12 * scale),
                    border: Border.all(
                      color: const Color(0xFFF2EFEA),
                      width: 1 * scale
                    )
                  ),
                  padding: EdgeInsets.all(8 * scale),
                  child: Image.asset(
                    'assets/product_images/${alert.itemCode}.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/product_images/${alert.itemCode}.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported_outlined,
                        size: 30 * scale,
                        color: const Color(0xFF9A9FA5),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16 * scale),
                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        alert.itemName,
                        style: TextStyle(
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D1F),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        'Created on ${DateFormat('dd MMM yyyy').format(alert.createdAt)}',
                        style: TextStyle(
                          fontSize: 10 * scale,
                          color: const Color(0xFF9A9FA5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      // Target price in bold terracotta
                      Row(
                        children: [
                          Text(
                            'Target:  ',
                            style: TextStyle(
                              fontSize: 11 * scale,
                              color: Color(0xFF1A1D1F).withValues(alpha: 0.6),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'RM ${alert.target_price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14 * scale,
                              color: const Color(0xFFB85A3A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: EdgeInsets.all(3 * scale),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded, // Refined palette actions: soft grey close
                          size: 15 * scale,
                          color: const Color(0xFF9A9FA5),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onEdit,
                      child: Icon(
                        Icons.edit_rounded,
                        size: 16 * scale,
                        color: const Color(0xFFB85A3A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
