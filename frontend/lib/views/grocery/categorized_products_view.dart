import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/grocery_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/favourite_view_model.dart';
import 'product_details_view.dart';
import '../widgets/common/grocery_card.dart';
import '../widgets/common/animated_notification.dart';

class CategorizedProductsView extends StatefulWidget {
  final String group;
  final String? category;
  final double scale;

  const CategorizedProductsView({
    super.key,
    required this.group,
    this.category,
    required this.scale,
  });

  @override
  State<CategorizedProductsView> createState() => _CategorizedProductsViewState();
}

class _CategorizedProductsViewState extends State<CategorizedProductsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<GroceryViewModel>();
    
    // Initial fetch
    Future.microtask(() => viewModel.fetchCategorizedProducts(
      group: widget.group,
      category: widget.category,
      isRefresh: true,
    ));

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<GroceryViewModel>().fetchCategorizedProducts(
        group: widget.group,
        category: widget.category,
        isRefresh: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroceryViewModel>();
    final favouriteViewModel = context.watch<FavouriteViewModel>();
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFFAF3),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category ?? widget.group,
          style: TextStyle(
            color: const Color(0xFF325E6A),
            fontSize: 16 * widget.scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: viewModel.isCategorizedLoading && viewModel.categorizedProducts.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1D1F)))
          : viewModel.categorizedProducts.isEmpty
              ? const Center(child: Text("No products found"))
              : CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        8 * widget.scale,
                        15 * widget.scale,
                        8 * widget.scale,
                        viewModel.hasMoreProducts ? 0 : 20 * widget.scale + MediaQuery.of(context).padding.bottom,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 6 * widget.scale,
                          mainAxisSpacing: 6 * widget.scale,
                          mainAxisExtent: 310 * widget.scale,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = viewModel.categorizedProducts[index];
                            final isFavourite = favouriteViewModel.favourites.contains(product.itemCode);
                            return GroceryCard(
                              product: product,
                              scale: widget.scale,
                              isFavourite: isFavourite,
                              onFavourite: () {
                                if (authViewModel.isLoggedIn) {
                                  favouriteViewModel.toggleFavourite(product.itemCode, authViewModel.accessToken!);
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
                          childCount: viewModel.categorizedProducts.length,
                        ),
                      ),
                    ),
                    if (viewModel.hasMoreProducts)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20 * widget.scale),
                            child: const CircularProgressIndicator(color: Color(0xFF1A1D1F)),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
