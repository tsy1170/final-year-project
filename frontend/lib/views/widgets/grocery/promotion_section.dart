import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  late PageController _pageController;
  static const int _infiniteFactor = 1000;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
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
    final authViewModel = context.watch<AuthViewModel>();
    final locationViewModel = context.watch<LocationViewModel>();
    final worthBuyingProducts = widget.viewModel.worthBuyingProducts;

    if (widget.viewModel.isWorthBuyingLoading && worthBuyingProducts.isEmpty) {
      return SizedBox(
        height: 230 * widget.scale,
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF1A1D1F))),
      );
    }

    if (worthBuyingProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            20 * widget.scale,
            10 * widget.scale,
            20 * widget.scale,
            15 * widget.scale,
          ),
          child: Text(
            'WORTH BUYING',
            style: TextStyle(
              fontSize: 16 * widget.scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D1F),
              letterSpacing: 0,
            ),
          ),
        ),
        SizedBox(
          height: 180 * widget.scale,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index % worthBuyingProducts.length;
              });
            },
            itemBuilder: (context, index) {
              final product = worthBuyingProducts[index % worthBuyingProducts.length];
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
        ),
        SizedBox(height: 10 * widget.scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            worthBuyingProducts.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: 2 * widget.scale),
              height: 3 * widget.scale,
              width: _currentPage == index
                  ? 16 * widget.scale
                  : 8 * widget.scale,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF1A1D1F)
                    : const Color(0xFF1A1D1F).withValues(alpha: 0.3),
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
    final imageUrl = product['image_url'];
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
          margin: EdgeInsets.fromLTRB(4 * scale, 0, 4 * scale, 14 * scale),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
              width: 1 * scale,
            ),
            borderRadius: BorderRadius.circular(12 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), // Shadow color
                  spreadRadius: -6,                     // How far the shadow extends
                  blurRadius: 6,                      // Softness of the shadow
                  offset: const Offset(0, 10),        // Offset of the shadow, 2),
                )
              ]
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: 130 * scale,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDFD),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12 * scale),
                        bottomLeft: Radius.circular(12 * scale),
                      ),
                    ),
                    padding: EdgeInsets.all(2 * scale),
                    child:
                    (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 40 * scale,
                              color: const Color(0xFF9A9FA5),
                            )
                    )
                        : Icon(
                      Icons.image_outlined,
                      size: 40 * scale,
                      color: const Color(0xFF9A9FA5),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        12 * scale,
                        12 * scale,
                        15 * scale,
                        12 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  itemName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12 * scale,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1D1F),
                                  ),
                                ),
                              ),
                              SizedBox(width: 15 * scale),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: onFavourite,
                                  customBorder: const CircleBorder(),
                                  child: Icon(
                                    isFavourite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 24 * scale,
                                    color: isFavourite
                                        ? const Color(0xFF325E6A)
                                        : const Color(0xFF1A1D1F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9A9FA5),
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
                                      premiseName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11 * scale,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A1D1F),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'RM $todayPrice',
                                          style: TextStyle(
                                            fontSize: 13 * scale,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1A1D1F),
                                          ),
                                        ),
                                        if (double.tryParse(priceReduction) != null && double.parse(priceReduction) > 0) ...[
                                          SizedBox(width: 8 * scale),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 1 * scale),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFED1A4B).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4 * scale),
                                            ),
                                            child: Text(
                                              '-RM $priceReduction',
                                              style: TextStyle(
                                                fontSize: 10 * scale,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFED1A4B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
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
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 50 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF325E6A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(11 * scale),
                      bottomRight: Radius.circular(11 * scale),
                    ),
                  ),

                  padding: EdgeInsets.symmetric(vertical: 1 * scale),
                  child: Text(
                    'Deals',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9 * scale,
                      fontWeight: FontWeight.w600,
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
