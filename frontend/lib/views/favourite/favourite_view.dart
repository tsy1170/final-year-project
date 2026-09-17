import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/favourite_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/location_view_model.dart';
import '../../views/grocery/item_groups_view.dart';
import '../widgets/favourite/favourite_compare_button.dart';
import '../widgets/favourite/favourite_empty_state.dart';
import '../widgets/favourite/favourite_logged_out_state.dart';
import '../widgets/favourite/favourite_list.dart';
import '../widgets/common/mesh_background.dart';
import 'compare_prices_view.dart';

class FavouriteView extends StatefulWidget {
  final double scale;

  const FavouriteView({super.key, required this.scale});

  @override
  State<FavouriteView> createState() => _FavouriteViewState();
}

class _FavouriteViewState extends State<FavouriteView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWorthBuying();
    });
  }

  void _fetchWorthBuying() {
    final favVM = context.read<FavouriteViewModel>();
    final authVM = context.read<AuthViewModel>();
    final locVM = context.read<LocationViewModel>();

    if (authVM.isLoggedIn && authVM.accessToken != null && locVM.currentPosition != null) {
      favVM.loadWorthBuyingFavourites(
        authVM.accessToken!,
        locVM.currentPosition!.latitude,
        locVM.currentPosition!.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FavouriteViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final locationViewModel = context.watch<LocationViewModel>();

    if (authViewModel.isLoggedIn && 
        viewModel.worthBuyingFavourites.isEmpty && 
        !viewModel.isWorthBuyingLoading && 
        locationViewModel.currentPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchWorthBuying());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'FAVOURITES',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 18 * widget.scale,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5
          ),
        ),
        actions: [
          if (authViewModel.isLoggedIn && viewModel.favouriteProducts.isNotEmpty)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComparePricesView(scale: widget.scale),
                  ),
                );
              },
              icon: Icon(
                Icons.compare_arrows_outlined,
                size: 30 * widget.scale,
                color: const Color(0xFFB85A3A),
              ),
            ),

          if (authViewModel.isLoggedIn)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemGroupsView(scale: widget.scale),
                  ),
                );
              },
              icon: Icon(
                Icons.add_circle_outline_rounded,
                size: 25 * widget.scale,
                color: const Color(0xFFB85A3A),
              ),
            ),
          SizedBox(width: 10 * widget.scale),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: MeshBackground()),
          SafeArea(
            child: Stack(
              children: [
                !authViewModel.isLoggedIn
                    ? FavouriteLoggedOutState(scale: widget.scale)
                    : viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1D1F)))
                        : viewModel.favouriteProducts.isEmpty
                            ? FavouriteEmptyState(scale: widget.scale)
                            : FavouriteList(
                                viewModel: viewModel,
                                authViewModel: authViewModel,
                                locationViewModel: locationViewModel,
                                scale: widget.scale,
                              ),
                if (authViewModel.isLoggedIn && viewModel.favouriteProducts.isNotEmpty)
                  FavouriteCompareButton(
                    scale: widget.scale,
                    itemCount: viewModel.favouriteProducts.length,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
