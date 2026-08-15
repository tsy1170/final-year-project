import 'package:flutter/material.dart';
import '../../../viewmodels/favourite_view_model.dart';
import '../../../viewmodels/auth_view_model.dart';
import 'favourite_item_card.dart';
import '../../product_details_view.dart';

class FavouriteList extends StatelessWidget {
  final FavouriteViewModel viewModel;
  final AuthViewModel authViewModel;
  final double scale;

  const FavouriteList({
    super.key,
    required this.viewModel,
    required this.authViewModel,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final double navBarHeight = MediaQuery.of(context).padding.bottom;
    
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(0, 0, 0, (80 + 60 + 25) * scale + navBarHeight),
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
}
