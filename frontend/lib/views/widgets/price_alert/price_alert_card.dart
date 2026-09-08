import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/price_alert.dart';
import '../../grocery/product_details_view.dart';

class PriceAlertCard extends StatelessWidget {
  final PriceAlert alert;
  final double scale;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PriceAlertCard({
    super.key,
    required this.alert,
    required this.scale,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            spreadRadius: -6,
            blurRadius: 8,
            offset: const Offset(4, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12 * scale),
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
            padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 15 * scale),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item image at left side
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8 * scale),
                    child: Container(
                      width: 80 * scale,
                      height: 80 * scale,
                      color: const Color(0xFFFFFDFD),
                      child:
                          alert.imageUrl != null && alert.imageUrl!.isNotEmpty
                          ? Image.network(
                              alert.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 30 * scale,
                                    color: Colors.grey,
                                  ),
                            )
                          : Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 40 * scale,
                            ),
                    ),
                  ),
                  SizedBox(width: 15 * scale),
                  // Item name, target price and created date in column besides the image
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.itemName,
                              style: TextStyle(
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1D1F),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 3 * scale),
                            Text(
                              'Created on ${DateFormat('dd MMM yyyy').format(alert.createdAt)}',
                              style: TextStyle(
                                fontSize: 11 * scale,
                                color: const Color(0xFF9A9FA5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        Text(
                          'Target: RM ${alert.target_price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14 * scale,
                            color: const Color(0xFF325E6A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 3 * scale),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(
                            Icons.close,
                            size: 16 * scale,
                            color: const Color(0xFFED1A4B),
                          ),
                        ),
                        GestureDetector(
                          onTap: onEdit,
                          child: Icon(
                            Icons.edit,
                            size: 16 * scale,
                            color: const Color(0xFF325E6A),
                          ),
                        ),
                      ],
                    ),
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
