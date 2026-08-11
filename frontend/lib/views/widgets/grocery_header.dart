import 'package:flutter/material.dart';
import '../../viewmodels/grocery_view_model.dart';
import '../search_page_view.dart';
import '../item_groups_view.dart';

class GroceryHeader extends StatelessWidget {
  const GroceryHeader({super.key, required this.scale, required this.viewModel});

  final double scale;
  final GroceryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFD)
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20 * scale,
            right: 20 * scale,
            top: 40 * scale,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GROCERY',
                  style: TextStyle(
                    color: const Color(0xFF1A1D1F),
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      constraints: const BoxConstraints(),
                      alignment: Alignment.center,
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        size: 24 * scale,
                        color: const Color(0xFF1A1D1F),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemGroupsView(scale: scale),
                          ),
                        );
                      },
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact, // Removes the internal padding
                      alignment: Alignment.center,
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
            left: 0 * scale,
            right: 0 * scale,
            top: 95 * scale,
            height: 45 * scale,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchPageView(scale: scale),
                  ),
                );
              },
              child: AbsorbPointer(
                child: TextField(
                  readOnly: true,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: const Color(0xFF1A1D1F),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search Items',
                    hintStyle: TextStyle(
                      fontSize: 12 * scale,
                      color: const Color(0xFF1A1D1F),
                      letterSpacing: 0
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20 * scale,
                        10 * scale,
                        10 * scale,
                        10 * scale,
                      ),
                      child: Icon(
                        Icons.search,
                        size: 20 * scale,
                        color: const Color(0xFF1A1D1F),
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
            ),
          ),
        ],
      ),
    );
  }
}

OutlineInputBorder searchBorder(double scale, {double width = 1.0}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(1 * scale),
      borderSide: BorderSide(
        color: Colors.grey.withValues(alpha: 0.3), 
        width: width * scale,
      ),
    );
