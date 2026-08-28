import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/favourite_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../views/grocery/item_groups_view.dart';
import '../widgets/favourite/favourite_compare_button.dart';
import '../widgets/favourite/favourite_empty_state.dart';
import '../widgets/favourite/favourite_logged_out_state.dart';
import '../widgets/favourite/favourite_list.dart';

class FavouriteView extends StatelessWidget {
  final double scale;

  const FavouriteView({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FavouriteViewModel>();
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAF3),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'FAVOURITES',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 18 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (authViewModel.isLoggedIn)
            IconButton(
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
                color: const Color(0xFF325E6A),
              ),
            ),
            SizedBox(width: 10 * scale),
        ],
        // bottom: PreferredSize(
        //   preferredSize: Size.fromHeight(1 * scale),
        //   child: Divider(
        //     height: 1 * scale,
        //     color: const Color(0xFF1A1D1F),
        //   ),
        // )
      ),
      body: Stack(
        children: [
          !authViewModel.isLoggedIn
              ? FavouriteLoggedOutState(scale: scale)
              : viewModel.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1D1F)))
              : viewModel.favouriteProducts.isEmpty
              ? FavouriteEmptyState(scale: scale)
              : FavouriteList(
            viewModel: viewModel,
            authViewModel: authViewModel,
            scale: scale,
          ),
          if (authViewModel.isLoggedIn &&
              viewModel.favouriteProducts.isNotEmpty)
            FavouriteCompareButton(
              scale: scale,
              itemCount: viewModel.favouriteProducts.length,
            ),
        ],
      ),
    );
  }
}
