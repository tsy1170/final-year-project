import 'package:flutter/material.dart';
import '../../models/grocery_product.dart';

class FavouriteItemCard extends StatelessWidget {
  final GroceryProduct product;
  final double scale;
  final bool isFavourite;
  final VoidCallback onFavourite;
  final VoidCallback onTap;

  const FavouriteItemCard({
    super.key,
    required this.product,
    required this.scale,
    this.isFavourite = true,
    required this.onFavourite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withValues(alpha: 0.3),
              width: 1 * scale,
            ),

          ),
          borderRadius: BorderRadius.circular(1 * scale),
        ),
        child: Row(
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
                      fontSize: 14 * scale,
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
                color: isFavourite ? const Color(0xFFED1A4B) : const Color(0xFF1A1D1F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
