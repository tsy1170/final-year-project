import 'package:flutter/material.dart';
import '../../../models/grocery_product.dart';

class FavouriteItemCard extends StatelessWidget {
  final GroceryProduct product;
  final double scale;
  final bool isFavourite;
  final VoidCallback onFavourite;
  final VoidCallback onTap;
  final Map<String, dynamic>? worthBuyingInfo;

  const FavouriteItemCard({
    super.key,
    required this.product,
    required this.scale,
    this.isFavourite = true,
    required this.onFavourite,
    required this.onTap,
    this.worthBuyingInfo,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12 * scale),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1 * scale,
          ),
          borderRadius: BorderRadius.circular(12 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              spreadRadius: -6,
              blurRadius: 8,
              offset: const Offset(4, 6),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Image at the left side
                SizedBox(
                  width: 80 * scale,
                  height: 80 * scale,
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image_not_supported, size: 40 * scale, color: Colors.grey),
                        )
                      : Icon(Icons.image, size: 80 * scale, color: Colors.grey),
                ),
                SizedBox(width: 15 * scale),
                // Item name and unit below the name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1D1F),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        product.unit,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9A9FA5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Favourite button at most right side
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onFavourite,
                  icon: Icon(
                    isFavourite ? Icons.favorite : Icons.favorite_border,
                    size: 24 * scale,
                    color: isFavourite ? const Color(0xFF325E6A) : const Color(0xFF1A1D1F),
                  ),
                ),
              ],
            ),
            if (worthBuyingInfo != null) ...[
              SizedBox(height: 12 * scale),
              Container(
                padding: EdgeInsets.all(10 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storefront_rounded, size: 14 * scale, color: const Color(0xFF325E6A)),
                        SizedBox(width: 6 * scale),
                        Expanded(
                          child: Text(
                            worthBuyingInfo!['premise_name'] ?? 'Unknown Store',
                            style: TextStyle(
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1D1F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6 * scale),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RM ${worthBuyingInfo!['today_price']?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1D1F),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
                          decoration: BoxDecoration(
                            color: const Color(0xFFED1A4B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4 * scale),
                          ),
                          child: Text(
                            '-RM ${worthBuyingInfo!['price_reduction']?.toStringAsFixed(2) ?? '0.00'}',
                            style: TextStyle(
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFED1A4B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
