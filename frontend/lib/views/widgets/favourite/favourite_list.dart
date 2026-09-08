import 'package:flutter/material.dart';
import '../../../viewmodels/favourite_view_model.dart';
import '../../../viewmodels/auth_view_model.dart';
import '../../../viewmodels/location_view_model.dart';
import 'favourite_item_card.dart';
import '../../grocery/product_details_view.dart';

class FavouriteList extends StatelessWidget {
  final FavouriteViewModel viewModel;
  final AuthViewModel authViewModel;
  final LocationViewModel locationViewModel;
  final double scale;

  const FavouriteList({
    super.key,
    required this.viewModel,
    required this.authViewModel,
    required this.locationViewModel,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final double navBarHeight = MediaQuery.of(context).padding.bottom;
    
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12 * scale, 10 * scale, 12 * scale, (100 + 60 + 25) * scale + navBarHeight),
      itemCount: viewModel.favouriteProducts.length,
      itemBuilder: (context, index) {
        final product = viewModel.favouriteProducts[index];
        final worthBuyingInfo = viewModel.getWorthBuyingInfo(product.itemCode);

        return Padding(
          padding: EdgeInsets.only(bottom: 6 * scale),
          child: FavouriteItemCard(
            product: product,
            scale: scale,
            isFavourite: true,
            worthBuyingInfo: worthBuyingInfo,
            onFavourite: () {
              viewModel.toggleFavourite(
                product.itemCode, 
                authViewModel.accessToken!,
                lat: locationViewModel.currentPosition?.latitude,
                lng: locationViewModel.currentPosition?.longitude,
              );
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
          ),
        );
      },
    );
  }
}
