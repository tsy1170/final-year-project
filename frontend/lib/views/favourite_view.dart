import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/grocery_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import 'widgets/favourite_item_card.dart';
import 'product_details_view.dart';
import 'item_groups_view.dart';
import 'login_view.dart';
import 'optimization_view.dart';

class FavouriteView extends StatelessWidget {
  final double scale;

  const FavouriteView({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroceryViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final double navBarHeight = MediaQuery.of(context).padding.bottom;

    return Container(
      color: const Color(0xFFFFFDFD),
      child: Stack(
        children: [
          Column(
            children: [
              // Header Bar
              Container(
                width: double.infinity,
                height: 90 * scale,
                padding: EdgeInsets.only(
                  top: 40 * scale,
                  left: 20 * scale,
                  right: 20 * scale,
                  bottom: 10 * scale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDFD),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                      width: 1 * scale,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FAVOURITES',
                      style: TextStyle(
                        color: const Color(0xFF1A1D1F),
                        fontSize: 21 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (authViewModel.isLoggedIn)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemGroupsView(scale: scale),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          size: 26 * scale,
                          color: const Color(0xFF1A1D1F),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: !authViewModel.isLoggedIn
                    ? _buildLoggedOutUI(context)
                    : viewModel.isFavouritesLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1D1F)))
                        : viewModel.favouriteProducts.isEmpty
                            ? _buildEmptyUI()
                            : _buildFavouritesList(context, viewModel, authViewModel),
              ),
            ],
          ),
          if (authViewModel.isLoggedIn && viewModel.favouriteProducts.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 70 * scale + navBarHeight,
              child: _buildCompareButton(context, viewModel),
            ),
        ],
      ),
    );
  }

  Widget _buildCompareButton(BuildContext context, GroceryViewModel viewModel) {
    return Container(
      width: double.infinity,
      height: 60 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFFED1A4B),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10 * scale,
            offset: Offset(0, -5 * scale),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OptimizationView(scale: scale),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${viewModel.favouriteProducts.length} ITEMS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'COMPARE ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20 * scale,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavouritesList(BuildContext context, GroceryViewModel viewModel, AuthViewModel authViewModel) {
    final double navBarHeight = MediaQuery.of(context).padding.bottom;
    
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(0, 0 * scale, 0, (80 + 60 + 25) * scale + navBarHeight),
      itemCount: viewModel.favouriteProducts.length,
      itemBuilder: (context, index) {
        final product = viewModel.favouriteProducts[index];
        return FavouriteItemCard(
          product: product,
          scale: scale,
          isFavourite: true,
          onFavourite: () {
            viewModel.toggleFavourite(product.itemCode, authViewModel.accessToken!);
          },
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsView(
                  itemCode: product.itemCode,
                  scale: scale,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 60 * scale,
            color: const Color(0xFF1A1D1F).withValues(alpha: 0.2),
          ),
          SizedBox(height: 15 * scale),
          Text(
            'Your list is empty',
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1D1F),
            ),
          ),
          SizedBox(height: 5 * scale),
        ],
      ),
    );
  }

  Widget _buildLoggedOutUI(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 50 * scale,
              color: const Color(0xFF1A1D1F).withValues(alpha: 0.2),
            ),
            SizedBox(height: 20 * scale),
            Text(
              'Login to see your favourites',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1D1F),
              ),
            ),
            SizedBox(height: 25 * scale),
            SizedBox(
              width: double.infinity,
              height: 50 * scale,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginView(scale: scale)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1D1F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1 * scale),
                  ),
                ),
                child: const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
