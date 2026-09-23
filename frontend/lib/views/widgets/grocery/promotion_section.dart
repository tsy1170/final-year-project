import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../viewmodels/grocery_view_model.dart';
import '../../../viewmodels/auth_view_model.dart';
import '../../../viewmodels/favourite_view_model.dart';
import '../../../viewmodels/location_view_model.dart';
import '../../grocery/product_details_view.dart';
import '../common/animated_notification.dart';

class PromotionSection extends StatefulWidget {
  final double scale;
  final GroceryViewModel viewModel;
  final FavouriteViewModel favouriteViewModel;

  const PromotionSection({
    super.key,
    required this.scale,
    required this.viewModel,
    required this.favouriteViewModel,
  });

  @override
  State<PromotionSection> createState() => _PromotionSectionState();
}

class _PromotionSectionState extends State<PromotionSection> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final locationViewModel = context.watch<LocationViewModel>();
    final worthBuyingProducts = widget.viewModel.worthBuyingProducts;

    if (widget.viewModel.isWorthBuyingLoading && worthBuyingProducts.isEmpty) {
      return SizedBox(
        height: 320 * widget.scale,
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF1A1D1F))),
      );
    }

    if (worthBuyingProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            30 * widget.scale,
            20 * widget.scale,
            20 * widget.scale,
            8 * widget.scale,
          ),
          child: Text(
            'DISCOVER',
            style: TextStyle(
              fontSize: 15 * widget.scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1D1F),
              letterSpacing: 1.2,
            ),
          ),
        ),
        CarouselSlider.builder(
          itemCount: worthBuyingProducts.length,
          options: CarouselOptions(
            height: 290 * widget.scale,
            viewportFraction: 0.82,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 6),
            onPageChanged: (index, reason) {
              setState(() {
                _currentPage = index;
              });
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final product = worthBuyingProducts[index];
            final itemCode = product['item_code'] as int;
            final isFavourite = widget.favouriteViewModel.favourites.contains(itemCode);

            return _PromotionCard(
              product: product,
              scale: widget.scale,
              isFavourite: isFavourite,
              onFavourite: () {
                if (authViewModel.isLoggedIn) {
                  final token = authViewModel.accessToken;
                  if (token != null) {
                    widget.favouriteViewModel.toggleFavourite(
                      itemCode,
                      token,
                      lat: locationViewModel.currentPosition?.latitude,
                      lng: locationViewModel.currentPosition?.longitude,
                    );
                    if (!isFavourite) {
                      showTopNotification(
                        context,
                        "Successfully Added to Favourites",
                        true,
                        widget.scale,
                      );
                    }
                  }
                } else {
                  showTopNotification(
                    context,
                    "Please login to add favourites",
                    false,
                    widget.scale,
                  );
                }
              },
            );
          },
        ),
        SizedBox(height: 15 * widget.scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            worthBuyingProducts.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.symmetric(horizontal: 3 * widget.scale),
              height: 4 * widget.scale,
              width: _currentPage == index
                  ? 20 * widget.scale
                  : 8 * widget.scale,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFFB85A3A)
                    : const Color(0xFF1A1D1F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2 * widget.scale),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final Map<String, dynamic> product;
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
    final itemCode = product['item_code'] as int;
    final itemName = product['item_name'] ?? 'Unknown Item';
    final unit = product['unit'] ?? '';
    final premiseName = product['premise_name'] ?? 'Unknown Premise';
    final todayPrice = product['today_price']?.toStringAsFixed(2) ?? '0.00';
    final priceReduction = product['price_reduction']?.toStringAsFixed(2) ?? '0.00';

    return GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProductDetailsView(
                      itemCode: itemCode,
                      scale: scale,
                    ),
              )
          );
        },
        child: Container(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.symmetric(vertical: 8 * scale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full-width image header fetching from local assets folder
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      height: 140 * scale,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.all(15 * scale),
                      child: Image.asset(
                        'assets/product_images/$itemCode.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/product_images/$itemCode.jpg',
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

                  // Product Details
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16 * scale, 12 * scale, 16 * scale, 16 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  itemName[0].toUpperCase() + itemName.substring(1).toLowerCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1D1F),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8 * scale),
                              Text(
                                unit,
                                style: TextStyle(
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF9A9FA5),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8 * scale),
                          Row(
                            children: [
                              Icon(Icons.storefront_rounded, size: 14 * scale, color: const Color(0xFFB85A3A)),
                              SizedBox(width: 6 * scale),
                              Expanded(
                                child: Text(
                                  premiseName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12 * scale,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF9A9FA5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'RM $todayPrice',
                                style: TextStyle(
                                  fontSize: 18 * scale,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFB85A3A),
                                ),
                              ),
                              if (double.tryParse(priceReduction) != null && double.parse(priceReduction) > 0)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF6F3),
                                    borderRadius: BorderRadius.circular(10 * scale),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.trending_down_rounded, size: 14 * scale, color: const Color(0xFFB85A3A)),
                                      SizedBox(width: 4 * scale),
                                      Text(
                                        '-RM $priceReduction',
                                        style: TextStyle(
                                          fontSize: 12 * scale,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFB85A3A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Favorite Button Overlay
              Positioned(
                top: 12 * scale,
                right: 12 * scale,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onFavourite,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: EdgeInsets.all(8 * scale),
                      child: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border,
                        size: 20 * scale,
                        color: isFavourite ? const Color(0xFFB85A3A) : const Color(0xFF1A1D1F),
                      ),
                    ),
                  ),
                ),
              ),

              // Deals Badge Overlay
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB85A3A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16 * scale),
                      bottomRight: Radius.circular(16 * scale),
                    ),
                  ),
                  child: Text(
                    'HOT DEAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }
}
