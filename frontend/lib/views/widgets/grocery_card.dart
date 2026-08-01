import 'package:flutter/material.dart';
import '../../models/grocery_product.dart';

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
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12 * scale),
              ),
              child: Container(
                height: 210 * scale,
                width: double.infinity,
                padding: EdgeInsets.all(8 * scale),
                child: product.imageUrl != null 
                  ? Image.network(product.imageUrl!, fit: BoxFit.contain)
                  : Image.asset(
                      'assets/figma/100_plus.png',
                      fit: BoxFit.contain,
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
                        GestureDetector(
                          onTap: onFavourite,
                          child: Icon(
                            isFavourite ? Icons.favorite : Icons.favorite_border,
                            size: 20 * scale,
                            color: isFavourite
                                ? const Color(0xFFED1A4B)
                                : const Color(0xFF1A1D1F),
                          ),
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
