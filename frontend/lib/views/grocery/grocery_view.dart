import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
import '../../viewmodels/grocery_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/favourite_view_model.dart';
import '../../viewmodels/location_view_model.dart';
import '../widgets/grocery/promotion_section.dart';
import '../widgets/grocery/shop_by_category.dart';
import '../widgets/common/grocery_card.dart';
import '../widgets/grocery/grocery_header.dart';
import '../widgets/common/animated_notification.dart';
import 'product_details_view.dart';

class GroceryView extends StatefulWidget {
  final double scale;
  const GroceryView({super.key, required this.scale});

  @override
  State<GroceryView> createState() => _GroceryViewState();
}

class _GroceryViewState extends State<GroceryView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationVM = context.read<LocationViewModel>();
      final groceryVM = context.read<GroceryViewModel>();
      if (locationVM.currentPosition != null) {
        groceryVM.loadWorthBuying(
          lat: locationVM.currentPosition!.latitude,
          lng: locationVM.currentPosition!.longitude,
        );
      }
      groceryVM.loadMostViewedProducts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      final viewModel = context.read<GroceryViewModel>();
      viewModel.loadProducts(isRefresh: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroceryViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final favouriteViewModel = context.watch<FavouriteViewModel>();
    final locationViewModel = context.watch<LocationViewModel>();
    final double navBarHeight = MediaQuery.of(context).padding.bottom;

    // Listen for location changes to trigger worth buying fetch if not yet loaded
    if (locationViewModel.currentPosition != null &&
        viewModel.worthBuyingProducts.isEmpty &&
        !viewModel.isWorthBuyingLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.loadWorthBuying(
          lat: locationViewModel.currentPosition!.latitude,
          lng: locationViewModel.currentPosition!.longitude,
        );
      });
    }

    const Color color1 = Color(0xFFF2EBE4); // Warm Linen (Dominant Body)
    const Color color2 = Color(0xFFE8CFBF); // Muted Terracotta Tint (Bottom-Right)
    const Color color3 = Color(0xFFD3DFE2);

    if (viewModel.isLoading && viewModel.allProducts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A1D1F)),
      );
    }

    return Stack(
      children: [
        // Mesh Gradient Background
        Positioned.fill(
          child: MeshGradient(
            points: [
              MeshGradientPoint(position: const Offset(0.0, 0.0), color: color3),
              MeshGradientPoint(position: const Offset(0.25, 0.25), color: color1),
              MeshGradientPoint(position: const Offset(0.5, 0.5), color: color1),
              MeshGradientPoint(position: const Offset(0.85, 0.2), color: color1),
              MeshGradientPoint(position: const Offset(0.2, 0.85), color: color1),
              MeshGradientPoint(position: const Offset(1.0, 1.0), color: color2),
            ],
            options: MeshGradientOptions(blend: 4, noiseIntensity: 0),
          ),
        ),
        Positioned.fill(
          child: RefreshIndicator(
            color: const Color(0xFFFFFDFD),
            backgroundColor: const Color(0xFF1A1D1F),
            edgeOffset: 140 * widget.scale,
            onRefresh: () async {
              await viewModel.loadProducts(isRefresh: true);
              if (locationViewModel.currentPosition != null) {
                await viewModel.loadWorthBuying(
                  lat: locationViewModel.currentPosition!.latitude,
                  lng: locationViewModel.currentPosition!.longitude,
                );
              }
              await viewModel.loadMostViewedProducts();
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: 140 * widget.scale)),
                
                // Most Viewed Section - Now at the top
                if (viewModel.mostViewedProducts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(30 * widget.scale, 20 * widget.scale, 20 * widget.scale, 5 * widget.scale),
                          child: Text(
                            "MOST VIEWED",
                            style: TextStyle(
                              fontSize: 14 * widget.scale,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1D1F),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 30 * widget.scale),
                          child: SizedBox(
                            height: 120 * widget.scale,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 15 * widget.scale, vertical: 12 * widget.scale),
                              itemCount: viewModel.mostViewedProducts.length,
                              itemBuilder: (context, index) {
                                final product = viewModel.mostViewedProducts[index];
                                final isFavourite = favouriteViewModel.favourites.contains(product.itemCode);

                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5 * widget.scale),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailsView(
                                            itemCode: product.itemCode,
                                            scale: widget.scale,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 260 * widget.scale,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16 * widget.scale),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      padding: EdgeInsets.all(12 * widget.scale),
                                      child: Row(
                                        children: [
                                          // Left side image
                                          Container(
                                            width: 70 * widget.scale,
                                            height: 70 * widget.scale,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12 * widget.scale),
                                              border: Border.all(
                                                color: const Color(0xFFF2EFEA),
                                                width: 1 * widget.scale
                                              )
                                            ),
                                            padding: EdgeInsets.all(5 * widget.scale),
                                            child: Image.asset(
                                              'assets/product_images/${product.itemCode}.png',
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                                'assets/product_images/${product.itemCode}.jpg',
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) => Icon(
                                                  Icons.image_not_supported_outlined,
                                                  size: 24 * widget.scale,
                                                  color: const Color(0xFF9A9FA5),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12 * widget.scale),
                                          // Right side name and fav button
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  product.name[0].toUpperCase() + product.name.substring(1).toLowerCase(),
                                                  style: TextStyle(
                                                    fontSize: 12 * widget.scale,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF1A1D1F),
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const Spacer(),
                                                Align(
                                                  alignment: Alignment.bottomRight,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      if (authViewModel.isLoggedIn) {
                                                        favouriteViewModel.toggleFavourite(
                                                          product.itemCode,
                                                          authViewModel.accessToken!,
                                                          lat: locationViewModel.currentPosition?.latitude,
                                                          lng: locationViewModel.currentPosition?.longitude,
                                                        );
                                                        if (!isFavourite) {
                                                          showTopNotification(context, "Successfully Added to Favourites", true, widget.scale);
                                                        }
                                                      } else {
                                                        showTopNotification(context, "Please login to add favourites", false, widget.scale);
                                                      }
                                                    },
                                                    child: Container(
                                                      padding: EdgeInsets.all(6 * widget.scale),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF9ECE6),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        isFavourite ? Icons.favorite : Icons.favorite_border,
                                                        size: 18 * widget.scale,
                                                        color: isFavourite ? const Color(0xFFB85A3A) : const Color(0xFF1A1D1F),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                SliverToBoxAdapter(
                  child: PromotionSection(scale: widget.scale, viewModel: viewModel, favouriteViewModel: favouriteViewModel,),
                ),
                SliverToBoxAdapter(
                  child: ShopByCategory(scale: widget.scale, viewModel: viewModel),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20 * widget.scale, 60 * widget.scale, 30 * widget.scale, 15 * widget.scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BROWSE',
                          style: TextStyle(
                            fontSize: 15 * widget.scale,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1D1F),
                            letterSpacing: 0,
                          ),
                        ),
                        Text(
                          'PRODUCTS',
                          style: TextStyle(
                            fontSize: 22 * widget.scale,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB85A3A),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(10 * widget.scale, 0, 10 * widget.scale, 10 * widget.scale),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8 * widget.scale,
                    crossAxisSpacing: 8 * widget.scale,
                    itemBuilder: (context, index) {
                      final product = viewModel.allProducts[index];
                      final isFavourite = favouriteViewModel.favourites.contains(product.itemCode);
                      return GroceryCard(
                        product: product,
                        scale: widget.scale,
                        isFavourite: isFavourite,
                        onFavourite: () {
                          if (authViewModel.isLoggedIn) {
                            favouriteViewModel.toggleFavourite(
                              product.itemCode, 
                              authViewModel.accessToken!,
                              lat: locationViewModel.currentPosition?.latitude,
                              lng: locationViewModel.currentPosition?.longitude,
                            );
                            if (!isFavourite) {
                              showTopNotification(context, "Successfully Added to Favourites", true, widget.scale);
                            }
                          } else {
                            showTopNotification(context, "Please login to add favourites", false, widget.scale);
                          }
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsView(
                                itemCode: product.itemCode,
                                scale: widget.scale,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: viewModel.allProducts.length,
                  ),
                ),
                if (viewModel.isLoading && viewModel.allProducts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20 * widget.scale),
                      child: const Center(child: CircularProgressIndicator(color: Color(0xFF1A1D1F))),
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: (80 + 25) * widget.scale + navBarHeight)),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GroceryHeader(scale: widget.scale, viewModel: viewModel),
        ),
      ],
    );
  }
}
