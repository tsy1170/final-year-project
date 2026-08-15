import 'package:flutter/material.dart';
import '../../../models/grocery_product.dart';

class GroceryCard extends StatelessWidget {
  const GroceryCard({
    super.key,
    required this.product,
    required this.scale,
    required this.isFavourite,
    required this.onFavourite,
    this.onTap,
  });

  final GroceryProduct product;
  final double scale;
  final bool isFavourite;
  final VoidCallback onFavourite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(1 * scale),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1 * scale
          )
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(1 * scale),
              ),
              child: Container(
                height: 210 * scale,
                width: double.infinity,
                padding: EdgeInsets.all(8 * scale),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                  ? Image.network(
                      product.imageUrl!, 
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported_outlined,
                        size: 40 * scale,
                        color: const Color(0xFF9A9FA5),
                      ),
                    )
                  : Icon(
                      Icons.image_outlined,
                      size: 40 * scale,
                      color: const Color(0xFF9A9FA5),
                    ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F1F1)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * scale,
                  vertical: 8 * scale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF1A1D1F),
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onFavourite,
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: EdgeInsets.all(5 * scale),
                              child: Icon(
                                isFavourite ? Icons.favorite : Icons.favorite_border,
                                size: 20 * scale,
                                color: isFavourite
                                    ? const Color(0xFFED1A4B)
                                    : const Color(0xFF1A1D1F),
                              ),
                            ),
                          )
                        ),
                      ],
                    ),
                    Text(
                      product.unit,
                      style: TextStyle(
                        color: const Color(0xFF9A9FA5),
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
