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
    return Container(
      margin: EdgeInsets.only(bottom: 12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16 * scale),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(12 * scale),
            child: Column(
              children: [
                Row(
                  children: [
                    // Image at the left side
                    Container(
                      width: 75 * scale,
                      height: 75 * scale,
                      padding: EdgeInsets.all(8 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12 * scale),
                      ),
                      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.image_not_supported_outlined, size: 30 * scale, color: const Color(0xFF9A9FA5)),
                            )
                          : Icon(Icons.image_outlined, size: 40 * scale, color: const Color(0xFF9A9FA5)),
                    ),
                    SizedBox(width: 15 * scale),
                    // Item name and unit below the name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name[0].toUpperCase() + product.name.substring(1).toLowerCase(),
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
                            product.unit,
                            style: TextStyle(
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9A9FA5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Favourite button at most right side
                    Material(
                      color: Colors.transparent,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onFavourite,
                        icon: Icon(
                          isFavourite ? Icons.favorite : Icons.favorite_border,
                          size: 22 * scale,
                          color: isFavourite ? const Color(0xFFB85A3A) : const Color(0xFF1A1D1F),
                        ),
                      ),
                    ),
                  ],
                ),
                if (worthBuyingInfo != null) ...[
                  SizedBox(height: 12 * scale),
                  Container(
                    padding: EdgeInsets.all(12 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5F0), // soft neutral tactile fill
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.storefront_rounded, size: 14 * scale, color: const Color(0xFFB85A3A)),
                            SizedBox(width: 8 * scale),
                            Expanded(
                              child: Text(
                                worthBuyingInfo!['premise_name'] ?? 'Unknown Store',
                                style: TextStyle(
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1D1F),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8 * scale),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RM ${worthBuyingInfo!['today_price']?.toStringAsFixed(2) ?? '0.00'}',
                              style: TextStyle(
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A1D1F),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF6F3),
                                borderRadius: BorderRadius.circular(6 * scale),
                              ),
                              child: Text(
                                '-RM ${worthBuyingInfo!['price_reduction']?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontSize: 10 * scale,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFB85A3A),
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
        ),
      ),
    );
  }
}
