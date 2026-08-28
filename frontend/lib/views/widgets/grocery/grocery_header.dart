import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/grocery_view_model.dart';
import '../../../viewmodels/navigation_view_model.dart';
import '../../grocery/search_page_view.dart';
import '../../grocery/item_groups_view.dart';

class GroceryHeader extends StatelessWidget {
  const GroceryHeader({
    super.key,
    required this.scale,
    required this.viewModel,
  });

  final double scale;
  final GroceryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160 * scale,
      decoration: const BoxDecoration(
          color: Color(0xFFFFFAF3),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(15),
        )
      ),
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
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20 * scale,
            right: 20 * scale,
            top: 95 * scale,
            height: 45 * scale,
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.read<NavigationViewModel>().setSelectedIndex(4);
                    },
                    borderRadius: BorderRadius.circular(20 * scale),
                    child: Padding(
                      padding: EdgeInsets.all(4 * scale),
                      child: Icon(
                        Icons.account_circle,
                        size: 26 * scale,
                        color: const Color(0xFF1A1D1F),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10 * scale),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchPageView(scale: scale),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDFD),
                        borderRadius: BorderRadius.circular(12 * scale),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                          width: 1 * scale,
                        )
                      ),
                      child: AbsorbPointer(
                        child: TextField(
                          textAlignVertical: TextAlignVertical.center,
                          readOnly: true,
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: const Color(0xFF1A1D1F),
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10 * scale,
                              vertical: 10 * scale
                            ),
                            hintText: 'Search Items',
                            hintStyle: TextStyle(
                                fontSize: 12 * scale,
                                color: const Color(0xFF1A1D1F).withValues(alpha: 0.6),
                                letterSpacing: 0),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20 * scale,
                              color: const Color(0xFF1A1D1F),
                            ),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 45 * scale,
                              minHeight: 20 * scale
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10 * scale),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ItemGroupsView(scale: scale),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20 * scale),
                    child: Padding(
                      padding: EdgeInsets.all(4 * scale),
                      child: Icon(
                        Icons.menu_rounded,
                        size: 26 * scale,
                        color: const Color(0xFF1A1D1F),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
