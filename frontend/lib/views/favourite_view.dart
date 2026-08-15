import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/favourite_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import 'widgets/favourite/favourite_header.dart';
import 'widgets/favourite/favourite_compare_button.dart';
import 'widgets/favourite/favourite_empty_state.dart';
import 'widgets/favourite/favourite_logged_out_state.dart';
import 'widgets/favourite/favourite_list.dart';

class FavouriteView extends StatelessWidget {
  final double scale;

  const FavouriteView({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FavouriteViewModel>();
    final authViewModel = context.watch<AuthViewModel>();

    return Container(
      color: const Color(0xFFFFFDFD),
      child: Stack(
        children: [
          Column(
            children: [
              FavouriteHeader(
                scale: scale,
                isLoggedIn: authViewModel.isLoggedIn,
              ),
              Expanded(
                child: !authViewModel.isLoggedIn
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
              ),
            ],
          ),
          if (authViewModel.isLoggedIn && viewModel.favouriteProducts.isNotEmpty)
            FavouriteCompareButton(
              scale: scale,
              itemCount: viewModel.favouriteProducts.length,
            ),
        ],
      ),
    );
  }
}
