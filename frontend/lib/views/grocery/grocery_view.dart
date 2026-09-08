import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    
    // Initial load of worth buying products if location is already available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationVM = context.read<LocationViewModel>();
      final groceryVM = context.read<GroceryViewModel>();
      if (locationVM.currentPosition != null) {
        groceryVM.loadWorthBuying(
          lat: locationVM.currentPosition!.latitude,
          lng: locationVM.currentPosition!.longitude,
        );
      }
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

    if (viewModel.isLoading && viewModel.allProducts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A1D1F)),
      );
    }

    return Stack(
      children: [
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
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: 160 * widget.scale)),
                SliverToBoxAdapter(
                  child: PromotionSection(scale: widget.scale, viewModel: viewModel, favouriteViewModel: favouriteViewModel,),
                ),
                SliverToBoxAdapter(
                  child: ShopByCategory(scale: widget.scale, viewModel: viewModel),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20 * widget.scale, 40 * widget.scale, 20 * widget.scale, 10 * widget.scale),
                    child: Center(
                      child: Text(
                        'ALL PRODUCTS',
                        style: TextStyle(
                          fontSize: 17 * widget.scale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D1F),
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(6 * widget.scale, 0, 6 * widget.scale, 10 * widget.scale),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 6 * widget.scale,
                      mainAxisSpacing: 6 * widget.scale,
                      mainAxisExtent: 310 * widget.scale,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = viewModel.allProducts[index];
                        final isFavourite = favouriteViewModel.favourites.contains(product.itemCode);
                        return GroceryCard(
                          product: product,
                          scale: widget.scale,
                          isFavourite: isFavourite,
                          onFavourite: () {
                            if (authViewModel.isLoggedIn) {
                              // PASSING LOCATION HERE TO TRIGGER WORTH BUYING CHECK
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
