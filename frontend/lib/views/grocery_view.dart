import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/grocery_view_model.dart';
import '../models/grocery_product.dart';

class GroceryView extends StatelessWidget {
  const GroceryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / 402;
            final viewModel = context.watch<GroceryViewModel>();

            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _GroceryHeader(
                  scale: scale,
                  viewModel: viewModel,
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      36 * scale,
                      24 * scale,
                      36 * scale,
                      24 * scale,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 22 * scale,
                      mainAxisSpacing: 13 * scale,
                      mainAxisExtent: 164 * scale,
                    ),
                    itemCount: viewModel.visibleProducts.length,
                    itemBuilder: (context, index) {
                      final product = viewModel.visibleProducts[index];
                      return GroceryCard(
                        product: product,
                        scale: scale,
                        isFavourite: viewModel.favourites.contains(product.name),
                        onFavourite: () => viewModel.toggleFavourite(product.name),
                      );
                    },
                  ),
                ),
                GroceryBottomNavigation(
                  scale: scale,
                  selectedIndex: viewModel.selectedIndex,
                  onTap: viewModel.setSelectedIndex,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GroceryHeader extends StatelessWidget {
  const _GroceryHeader({
    required this.scale,
    required this.viewModel,
  });

  final double scale;
  final GroceryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 190 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC83A),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(15 * scale),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 33 * scale,
            top: 28 * scale,
            child: Text(
              'GROCERY',
              style: TextStyle(
                color: const Color(0xFF1A1D1F),
                fontSize: 25 * scale,
                fontWeight: FontWeight.w700,
                height: 38 / 25,
              ),
            ),
          ),
          Positioned(
            left: 251 * scale,
            top: 47 * scale,
            width: 145 * scale,
            height: 130 * scale,
            child: Image.asset('assets/figma/header_art.png'),
          ),
          Positioned(
            left: 28 * scale,
            right: 30 * scale,
            top: 79 * scale,
            height: 37 * scale,
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
                  child: Image.asset('assets/figma/search.png'),
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 52 * scale,
                  minHeight: 37 * scale,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 9 * scale),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: _searchBorder(scale),
                focusedBorder: _searchBorder(scale, width: 1.5),
              ),
            ),
          ),
          Positioned(
            left: 28 * scale,
            top: 129 * scale,
            width: 165 * scale,
            height: 30 * scale,
            child: GroceryDropdown(
              value: viewModel.category,
              items: const ['All Categories', 'Fresh Food', 'Beverages'],
              scale: scale,
              onChanged: (val) => viewModel.setCategory(val!),
            ),
          ),
          Positioned(
            left: 207 * scale,
            top: 129 * scale,
            width: 165 * scale,
            height: 30 * scale,
            child: GroceryDropdown(
              value: viewModel.subCategory,
              items: const ['Sub Category', 'Chicken', 'Fruit', 'Vegetable'],
              scale: scale,
              onChanged: (val) => viewModel.setSubCategory(val!),
            ),
          ),
        ],
      ),
    );
  }
}

OutlineInputBorder _searchBorder(double scale, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(28 * scale),
      borderSide: BorderSide(color: const Color(0x80000000), width: width),
    );

class GroceryDropdown extends StatelessWidget {
  const GroceryDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.scale,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final double scale;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down,
        size: 18 * scale,
        color: const Color(0xFF1A1D1F),
      ),
      style: TextStyle(
        color: const Color(0xFF354349),
        fontSize: 10 * scale,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.fromLTRB(10 * scale, 0, 7 * scale, 0),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: _dropdownBorder(scale),
        focusedBorder: _dropdownBorder(scale),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

OutlineInputBorder _dropdownBorder(double scale) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(20 * scale),
  borderSide: const BorderSide(color: Color(0x80000000)),
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
        color: const Color(0xFFF8F9FB),
        border: Border.all(color: const Color(0xFFCFCFCF)),
        borderRadius: BorderRadius.circular(3 * scale),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 46 * scale,
            top: 16 * scale,
            width: 60 * scale,
            height: 60 * scale,
            child: Container(
              padding: EdgeInsets.all(4 * scale),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCFCFCF)),
                borderRadius: BorderRadius.circular(3 * scale),
              ),
              child: Image.asset('assets/figma/image_placeholder.png'),
            ),
          ),
          Positioned(
            left: 16 * scale,
            right: 16 * scale,
            top: 89 * scale,
            child: const Divider(height: 1, color: Color(0xFFCFCFCF)),
          ),
          Positioned(
            left: 19 * scale,
            top: 99 * scale,
            width: 80 * scale,
            height: 31 * scale,
            child: Text(
              product.name,
              style: TextStyle(
                color: const Color(0xFF354349),
                fontSize: 10 * scale,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          Positioned(
            right: 12 * scale,
            top: 98 * scale,
            width: 23 * scale,
            height: 23 * scale,
            child: IconButton(
              padding: EdgeInsets.all(2 * scale),
              onPressed: onFavourite,
              icon: isFavourite
                  ? Icon(
                      Icons.favorite,
                      size: 19 * scale,
                      color: const Color(0xFFFFC83A),
                    )
                  : Image.asset('assets/figma/heart.png'),
            ),
          ),
          Positioned(
            left: 19 * scale,
            top: 135 * scale,
            child: Text(
              product.unit,
              style: TextStyle(
                color: const Color(0x80000000),
                fontSize: 10 * scale,
                fontWeight: FontWeight.w600,
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
      height: 80 * scale,
      padding: EdgeInsets.symmetric(horizontal: 24 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            index: 0,
            selectedIndex: selectedIndex,
            label: 'Cart',
            icon: Icons.shopping_cart_outlined,
            onTap: onTap,
            scale: scale,
          ),
          _NavItem(
            index: 1,
            selectedIndex: selectedIndex,
            label: 'Favourites',
            asset: 'assets/figma/favourites.png',
            onTap: onTap,
            scale: scale,
          ),
          _NavItem(
            index: 2,
            selectedIndex: selectedIndex,
            label: 'Complaint',
            asset: 'assets/figma/complaint.png',
            onTap: onTap,
            scale: scale,
          ),
          _NavItem(
            index: 3,
            selectedIndex: selectedIndex,
            label: 'Profile',
            asset: 'assets/figma/profile.png',
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
    this.asset,
    this.icon,
    required this.onTap,
    required this.scale,
  });
  final int index;
  final int selectedIndex;
  final String label;
  final String? asset;
  final IconData? icon;
  final ValueChanged<int> onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 * scale : 10 * scale,
          vertical: 8 * scale,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFC83A) : Colors.transparent,
          borderRadius: BorderRadius.circular(25 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 24 * scale,
                color: const Color(0xFF1A1D1F),
              )
            else
              Image.asset(
                asset!,
                width: 25 * scale,
                height: 25 * scale,
              ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: SizedBox(
                  width: isSelected ? null : 0,
                  child: Padding(
                    padding: EdgeInsets.only(left: isSelected ? 8 * scale : 0),
                    child: Text(
                      isSelected ? label : '',
                      maxLines: 1,
                      style: TextStyle(
                        color: const Color(0xFF1A1D1F),
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
