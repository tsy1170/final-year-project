import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/grocery_view_model.dart';
import 'widgets/promotion_section.dart';
import 'widgets/shop_by_category.dart';
import 'widgets/grocery_card.dart';
import 'widgets/grocery_bottom_navigation.dart';
import 'widgets/grocery_header.dart';

class GroceryView extends StatelessWidget {
  const GroceryView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / 402;
              final viewModel = context.watch<GroceryViewModel>();
              double navBarHeight = MediaQuery.of(context).padding.bottom;

              if (viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFC83A), Color(0xFFFFFDFD)],
                  ),
                ),
                child: Stack(
                  children: [
                    // 1. Scrollable Content
                    Positioned.fill(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Header space offset
                          SliverToBoxAdapter(
                            child: SizedBox(height: 160 * scale),
                          ),
                          // Promotion Section
                          SliverToBoxAdapter(
                            child: PromotionSection(
                              scale: scale,
                              viewModel: viewModel,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: ShopByCategory(
                              scale: scale,
                              viewModel: viewModel,
                            ),
                          ),
                          // Section Title for "All Items"
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(20 * scale, 40 * scale, 20 * scale, 20 * scale),
                              child: Text(
                                'All Products',
                                style: TextStyle(
                                  fontSize: 18 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1D1F),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          // The Grid of Products
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              10 * scale,
                              0,
                              10 * scale,
                              (80 + 25) * scale + navBarHeight,
                            ),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 6 * scale,
                                mainAxisSpacing: 6 * scale,
                                mainAxisExtent: 310 * scale,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final product = viewModel.visibleProducts[index];
                                  return GroceryCard(
                                    product: product,
                                    scale: scale,
                                    isFavourite: viewModel.favourites.contains(product.name),
                                    onFavourite: () => viewModel.toggleFavourite(product.name),
                                  );
                                },
                                childCount: viewModel.visibleProducts.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 2. Blurred Header at the top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: GroceryHeader(scale: scale, viewModel: viewModel),
                    ),
                    Positioned(
                      bottom: 10 + navBarHeight,
                      left: 15,
                      right: 15,
                      child: GroceryBottomNavigation(
                        scale: scale,
                        selectedIndex: viewModel.selectedIndex,
                        onTap: viewModel.setSelectedIndex,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
