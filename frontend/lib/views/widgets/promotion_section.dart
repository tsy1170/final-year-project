import 'package:flutter/material.dart';
import '../../models/grocery_product.dart';
import '../../viewmodels/grocery_view_model.dart';

class PromotionSection extends StatefulWidget {
  final double scale;
  final GroceryViewModel viewModel;

  const PromotionSection({super.key, required this.scale, required this.viewModel});

  @override
  State<PromotionSection> createState() => _PromotionSectionState();
}

class _PromotionSectionState extends State<PromotionSection> {
  late PageController _pageController;
  static const int _infiniteFactor = 1000;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Start in the middle of a very large count to allow "infinite" swiping in both directions
    _pageController = PageController(
      viewportFraction: 0.9,
      initialPage: 10 * (_infiniteFactor ~/ 2),
    );
    _currentPage = 0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Take max 10 items for promotions as requested
    final promoProducts = widget.viewModel.visibleProducts.take(10).toList();
    if (promoProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20 * widget.scale, 20 * widget.scale, 20 * widget.scale, 20 * widget.scale),
          child: Text(
            'Promotions',
            style: TextStyle(
              fontSize: 18 * widget.scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D1F),
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(
          height: 180 * widget.scale,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index % promoProducts.length;
              });
            },
            itemBuilder: (context, index) {
              final product = promoProducts[index % promoProducts.length];
              return _PromotionCard(
                product: product,
                scale: widget.scale,
                isFavourite: widget.viewModel.favourites.contains(product.name),
                onFavourite: () => widget.viewModel.toggleFavourite(product.name),
              );
            },
          ),
        ),
        SizedBox(height: 10 * widget.scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            promoProducts.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              margin: EdgeInsets.symmetric(horizontal: 2 * widget.scale),
              height: 3 * widget.scale,
              width: _currentPage == index ? 16 * widget.scale : 8 * widget.scale,
              decoration: BoxDecoration(
                color: _currentPage == index 
                    ? const Color(0xFF1A1D1F) 
                    : const Color(0xFF1A1D1F).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(0 * widget.scale),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final GroceryProduct product;
  final double scale;
  final bool isFavourite;
  final VoidCallback onFavourite;

  const _PromotionCard({
    required this.product,
    required this.scale,
    required this.isFavourite,
    required this.onFavourite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.fromLTRB(
          5 * scale,
          0,
          5 * scale,
          14 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.3),
          width: 0.5 * scale,
        ),
        borderRadius: BorderRadius.circular(1 * scale),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            offset: Offset(2, 4 * scale),
            blurRadius: 8 * scale,
          )
        ]
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // Image placeholder
              Container(
                width: 130 * scale,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(1 * scale),
                    bottomLeft: Radius.circular(1 * scale),
                  ),
                ),
                padding: EdgeInsets.all(2 * scale),
                child: Image.asset(
                  'assets/figma/100_plus.png',
                  fit: BoxFit.contain,
                ),
              ),
              // Info Section
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 12 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D1F),
                        ),
                      ),
                      Text(
                        product.unit,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1D1F).withValues(alpha: 0.6),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pulau-Pinang Sunshine Mart',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11 * scale,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1D1F),
                                  ),
                                ),
                                Text(
                                  'RM 3.50',
                                  style: TextStyle(
                                    fontSize: 16 * scale,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFED1A4B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ),
              Container (
                padding: EdgeInsets.fromLTRB(
                  0,
                  110 * scale,
                  23 * scale,
                  10 * scale,
                ),
                child: GestureDetector(
                  onTap: onFavourite,
                  child: Icon(
                    isFavourite ? Icons.favorite : Icons.favorite_border,
                    size: 24 * scale,
                    color: isFavourite
                        ? const Color(0xFFED1A4B)
                        : const Color(0xFF1A1D1F),
                  ),
                ),
              )
            ],
          ),
          Positioned(
            top: 15 * scale,
            right: -36 * scale,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 120 * scale,
                color: const Color(0xFFED1A4B),
                padding: EdgeInsets.symmetric(vertical: 2 * scale),
                child: Text(
                  'Promo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
