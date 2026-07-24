import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/grocery_view_model.dart';
import '../models/grocery_product.dart';

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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                          // Section Title for "All Items"
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(20 * scale, 25 * scale, 20 * scale, 15 * scale),
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
                                crossAxisSpacing: 8 * scale,
                                mainAxisSpacing: 8 * scale,
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
                      child: _GroceryHeader(scale: scale, viewModel: viewModel),
                    ),
                    // 3. Blurred Bottom Navigation at the bottom
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

class PromotionSection extends StatefulWidget {
  final double scale;
  final GroceryViewModel viewModel;

  const PromotionSection({super.key, required this.scale, required this.viewModel});

  @override
  State<PromotionSection> createState() => _PromotionSectionState();
}

class _PromotionSectionState extends State<PromotionSection> {
  late PageController _pageController;
  static const int _infiniteFactor = 1000;

  @override
  void initState() {
    super.initState();
    // Start in the middle of a very large count to allow "infinite" swiping in both directions
    _pageController = PageController(
      viewportFraction: 0.9,
      initialPage: 10 * (_infiniteFactor ~/ 2),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Take max 10 items for promotions as requested
    final promoProducts = widget.viewModel.visibleProducts.take(10).toList();
    if (promoProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * widget.scale, vertical: 10 * widget.scale),
          child: Text(
            'Promotions',
            style: TextStyle(
              fontSize: 18 * widget.scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D1F),
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(
          height: 180 * widget.scale,
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final product = promoProducts[index % promoProducts.length];
              return _PromotionCard(
                product: product,
                scale: widget.scale,
                isFavourite: widget.viewModel.favourites.contains(product.name),
                onFavourite: () => widget.viewModel.toggleFavourite(product.name),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final GroceryProduct product;
  final double scale;
  final bool isFavourite;
  final VoidCallback onFavourite;

  const _PromotionCard({
    required this.product,
    required this.scale,
    required this.isFavourite,
    required this.onFavourite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.fromLTRB(
          10 * scale,
          0,
          10 * scale,
          14 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF6E4C1),
        borderRadius: BorderRadius.circular(1 * scale),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            offset: Offset(2, 4 * scale),
            blurRadius: 8 * scale,
          )
        ]
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // Image placeholder
              Container(
                width: 110 * scale,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(1 * scale),
                    bottomLeft: Radius.circular(1 * scale),
                  ),
                ),
                padding: EdgeInsets.all(2 * scale),
                child: Image.asset(
                  'assets/figma/100_plus.png',
                  fit: BoxFit.contain,
                ),
              ),
              // Info Section
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 12 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D1F),
                        ),
                      ),
                      Text(
                        product.unit,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1D1F).withValues(alpha: 0.6),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pulau-Pinang Sunshine Mart',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11 * scale,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1D1F),
                                  ),
                                ),
                                Text(
                                  'RM 3.50',
                                  style: TextStyle(
                                    fontSize: 16 * scale,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFED1A4B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ),
              Container (
                padding: EdgeInsets.fromLTRB(
                  0,
                  110 * scale,
                  23 * scale,
                  10 * scale,
                ),
                child: GestureDetector(
                  onTap: onFavourite,
                  child: Icon(
                    isFavourite ? Icons.favorite : Icons.favorite_border,
                    size: 24 * scale,
                    color: isFavourite
                        ? const Color(0xFFED1A4B)
                        : const Color(0xFF1A1D1F),
                  ),
                ),
              )
            ],
          ),
          // Diagonal HOT DEAL Tag
          Positioned(
            top: 15 * scale,
            right: -36 * scale,
            child: Transform.rotate(
              angle: 0.785398, // 45 degrees
              child: Container(
                width: 120 * scale,
                color: const Color(0xFFED1A4B),
                padding: EdgeInsets.symmetric(vertical: 2 * scale),
                child: Text(
                  'Promo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroceryHeader extends StatelessWidget {
  const _GroceryHeader({required this.scale, required this.viewModel});

  final double scale;
  final GroceryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(25 * scale),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 160 * scale,
          color: Colors.white.withValues(alpha: 0.0),
          child: Stack(
            children: [
              Positioned(
                left: 33 * scale,
                top: 50 * scale,
                child: Text(
                  'GROCERY',
                  style: TextStyle(
                    color: const Color(0xFF1A1D1F),
                    fontSize: 25 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                left: 28 * scale,
                right: 30 * scale,
                top: 95 * scale,
                height: 46 * scale,
                child: TextField(
                  controller: viewModel.searchController,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: const Color(0xFF354349),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search Items',
                    hintStyle: TextStyle(
                      fontSize: 12 * scale,
                      color: const Color(0xFF354349),
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(10 * scale),
                      child: Icon(
                        Icons.search,
                        size: 20 * scale,
                        color: const Color(0xFF354349),
                      ),
                    ),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 52 * scale,
                      minHeight: 37 * scale,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 9 * scale),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.8),
                    enabledBorder: _searchBorder(scale),
                    focusedBorder: _searchBorder(scale, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

OutlineInputBorder _searchBorder(double scale, {double width = 0.5}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(28 * scale),
      borderSide: BorderSide(color: const Color(0x80000000), width: width),
    );

class GroceryCard extends StatelessWidget {
  const GroceryCard({
    super.key,
    required this.product,
    required this.scale,
    required this.isFavourite,
    required this.onFavourite,
  });

  final GroceryProduct product;
  final double scale;
  final bool isFavourite;
  final VoidCallback onFavourite;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1 * scale),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(12 * scale),
            ),
            child: Container(
              height: 210 * scale,
              width: double.infinity,
              padding: EdgeInsets.all(8 * scale),
              child: Image.asset(
                'assets/figma/100_plus.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F1F1)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 8 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF1A1D1F),
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onFavourite,
                        child: Icon(
                          isFavourite ? Icons.favorite : Icons.favorite_border,
                          size: 20 * scale,
                          color: isFavourite
                              ? const Color(0xFFED1A4B)
                              : const Color(0xFF1A1D1F),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    product.unit,
                    style: TextStyle(
                      color: const Color(0xFF9A9FA5),
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GroceryBottomNavigation extends StatelessWidget {
  const GroceryBottomNavigation({
    super.key,
    required this.scale,
    required this.selectedIndex,
    required this.onTap,
  });
  final double scale;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70 * scale,
      padding: EdgeInsets.symmetric(horizontal: 24 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(45 * scale),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0x26000000),
            offset: Offset(0, 4 * scale),
            blurRadius: 10 * scale,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            index: 0,
            selectedIndex: selectedIndex,
            label: 'Grocery',
            icon: Icons.shopping_cart_outlined,
            onTap: onTap,
            scale: scale,
          ),
          _NavItem(
            index: 1,
            selectedIndex: selectedIndex,
            label: 'Favourites',
            icon: Icons.favorite_border,
            onTap: onTap,
            scale: scale,
          ),
          _NavItem(
            index: 2,
            selectedIndex: selectedIndex,
            label: 'Complaint',
            icon: Icons.feedback_outlined,
            onTap: onTap,
            scale: scale,
          ),
          _NavItem(
            index: 3,
            selectedIndex: selectedIndex,
            label: 'Profile',
            icon: Icons.person_outline,
            onTap: onTap,
            scale: scale,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.scale,
  });
  final int index;
  final int selectedIndex;
  final String label;
  final IconData? icon;
  final ValueChanged<int> onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.lightImpact(); // Add physical feel
          onTap(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 * scale : 12 * scale,
          vertical: 8 * scale,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFC83A) : Colors.transparent,
          borderRadius: BorderRadius.circular(25 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24 * scale, color: const Color(0xFF1A1D1F)),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: SizedBox(
                  width: isSelected ? null : 0,
                  child: isSelected
                      ? Padding(
                    padding: EdgeInsets.only(left: 8 * scale),
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: const Color(0xFF1A1D1F),
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
