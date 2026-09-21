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
    // Generate a deterministic aspect ratio based on the item code so that the 
    // Masonry Grid keeps its beautiful staggered layout asymmetry, but the height 
    // is pre-allocated instantly before the asset loads. This completely prevents jittering.
    final double deterministicAspectRatio = (product.itemCode % 2 == 0) ? 1.0 : 1.15;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12 * scale),
                  ),
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    // Pre-allocates exact dimensions instantly, eliminating layout jumps entirely
                    child: AspectRatio(
                      aspectRatio: deterministicAspectRatio,
                      child: Padding(
                        padding: EdgeInsets.all(15 * scale),
                        child: Image.asset(
                          'assets/product_images/${product.itemCode}.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/product_images/${product.itemCode}.jpg',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_not_supported_outlined,
                              size: 40 * scale,
                              color: const Color(0xFF9A9FA5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 15 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name[0].toUpperCase() + product.name.substring(1).toLowerCase(),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF1A1D1F),
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Row(
                        children: [
                          Text(
                            product.unit,
                            style: TextStyle(
                              color: const Color(0xFF9A9FA5),
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.keyboard_arrow_right,
                            size: 20 * scale,
                            color: const Color(0xFFB85A3A),
                          )
                        ],
                      ),

                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8 * scale,
              right: 8 * scale,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onFavourite,
                  borderRadius: BorderRadius.circular(12 * scale),
                  child: Container(
                    padding: EdgeInsets.all(6 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9ECE6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Icon(
                      isFavourite ? Icons.favorite : Icons.favorite_border,
                      size: 18 * scale,
                      color: isFavourite
                          ? const Color(0xFFB85A3A)
                          : const Color(0xFF1A1D1F),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
