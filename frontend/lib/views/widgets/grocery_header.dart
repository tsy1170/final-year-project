import 'dart:ui';
import 'package:flutter/material.dart';
import '../../viewmodels/grocery_view_model.dart';

class GroceryHeader extends StatelessWidget {
  const GroceryHeader({super.key, required this.scale, required this.viewModel});

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
                left: 20 * scale,
                right: 20 * scale,
                top: 50 * scale,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GROCERY',
                      style: TextStyle(
                        color: const Color(0xFF1A1D1F),
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.notifications_none_rounded,
                            size: 24 * scale,
                            color: const Color(0xFF1A1D1F),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.menu_rounded,
                            size: 24 * scale,
                            color: const Color(0xFF1A1D1F),
                          ),
                        ),
                      ],
                    )
                  ],
                )
              ),
              Positioned(
                left: 20 * scale,
                right: 20 * scale,
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
                    enabledBorder: searchBorder(scale),
                    focusedBorder: searchBorder(scale, width: 1.5),
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

OutlineInputBorder searchBorder(double scale, {double width = 0.5}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(1 * scale),
      borderSide: BorderSide(color: const Color(0x80000000), width: width),
    );
