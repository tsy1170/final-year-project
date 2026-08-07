import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/grocery_view_model.dart';
import 'widgets/promotion_section.dart';
import 'widgets/shop_by_category.dart';
import 'widgets/grocery_card.dart';
import 'widgets/grocery_bottom_navigation.dart';
import 'widgets/grocery_header.dart';
import 'product_details_view.dart';
import 'profile_view.dart';

class GroceryView extends StatefulWidget {
  const GroceryView({super.key});

  @override
  State<GroceryView> createState() => _GroceryViewState();
}

class _GroceryViewState extends State<GroceryView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Initialize PageController with the current index from the ViewModel
    final viewModel = context.read<GroceryViewModel>();
    _pageController = PageController(initialPage: viewModel.selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroceryViewModel>();

    // Synchronize PageView position with ViewModel's selectedIndex when it changes
    if (_pageController.hasClients) {
      if (_pageController.page?.round() != viewModel.selectedIndex) {
        _pageController.jumpToPage(
          viewModel.selectedIndex
        );
      }
    }

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
              final double navBarHeight = MediaQuery.of(context).padding.bottom;

              return Container(
                color: const Color(0xFFFFFDFD),
                child: Stack(
                  children: [
                    // 1. Content Layer with PageView for smooth sliding animations
                    Positioned.fill(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(), // Navigation is controlled via BottomNav
                        children: [
                          _buildGroceryPage(context, viewModel, scale, navBarHeight),
                          _buildSimplePage('Favourites', scale),
                          _buildSimplePage('Complaint', scale),
                          ProfileView(scale: scale),
                        ],
                      ),
                    ),
                    
                    // 2. Bottom Navigation (Fixed overlay)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
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

  /// Builds a simple placeholder page with a consistent header height
  Widget _buildSimplePage(String title, double scale) {
    return Column(
      children: [
        // Header to maintain height consistency across pages
        Container(
          width: double.infinity,
          height: 160 * scale,
          padding: EdgeInsets.only(top: 45 * scale, left: 20 * scale),
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: TextStyle(
              color: const Color(0xFF1A1D1F),
              fontSize: 24 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text('$title Coming Soon'),
          ),
        ),
      ],
    );
  }

  /// Wraps the Grocery content and its header so they animate together
  Widget _buildGroceryPage(
    BuildContext context, 
    GroceryViewModel viewModel, 
    double scale, 
    double navBarHeight
  ) {
    return Stack(
      children: [
        Positioned.fill(
          child: _buildGroceryContent(context, viewModel, scale, navBarHeight),
        ),
        // Positioned header inside the page ensures it slides with the page content
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GroceryHeader(scale: scale, viewModel: viewModel),
        ),
      ],
    );
  }

  /// The original grocery scrollable content
  Widget _buildGroceryContent(
    BuildContext context, 
    GroceryViewModel viewModel, 
    double scale, 
    double navBarHeight
  ) {
    if (viewModel.isLoading && viewModel.visibleProducts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A1D1F)),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Space for the overlay header
        SliverToBoxAdapter(child: SizedBox(height: 160 * scale)),
        SliverToBoxAdapter(
          child: PromotionSection(scale: scale, viewModel: viewModel),
        ),
        SliverToBoxAdapter(
          child: ShopByCategory(scale: scale, viewModel: viewModel),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20 * scale, 40 * scale, 20 * scale, 10 * scale),
            child: Center(
              child: Text(
                'ALL PRODUCTS',
                style: TextStyle(
                  fontSize: 17 * scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D1F),
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            6 * scale,
            0,
            6 * scale,
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
              childCount: viewModel.visibleProducts.length,
            ),
          ),
        ),
      ],
    );
  }
}
