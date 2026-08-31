import 'package:flutter/material.dart';
import '../../../viewmodels/grocery_view_model.dart';
import '../../grocery/item_groups_view.dart';

class ShopByCategory extends StatelessWidget {
  final double scale;
  final GroceryViewModel viewModel;

  const ShopByCategory({
    super.key,
    required this.scale,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            20 * scale,
            50 * scale,
            20 * scale,
            15 * scale,
          ),
            child: Text(
              "SHOP BY CATEGORY",
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF325E6A),
                letterSpacing: 0,
              ),
            ),
        ),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemGroupsView(
                  scale: scale,
                  initialExpandedGroup: "BARANGAN SEGAR",
                ),
              ),
            );
          },
          child: Container(
            height: 90 * scale,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(
              horizontal: 20 * scale,
              vertical: 10 * scale,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDFD),
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1 * scale,
                ),
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1 * scale,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "BARANGAN SEGAR",
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1D1F),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right,
                  size: 24 * scale,
                  color: const Color(0xFF1A1D1F),
                ),
              ],
            ),
          ),
        ),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemGroupsView(
                  scale: scale,
                  initialExpandedGroup: "BARANGAN KERING",
                ),
              ),
            );
          },
          child: Container(
            height: 90 * scale,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(
              horizontal: 20 * scale,
              vertical: 15 * scale,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDFD),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1 * scale,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "BARANGAN KERING",
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1D1F),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right,
                  size: 24 * scale,
                  color: const Color(0xFF1A1D1F),
                ),
              ],
            ),
          ),
        ),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemGroupsView(
                  scale: scale,
                  initialExpandedGroup: "BARANGAN BERBUNGKUS",
                ),
              ),
            );
          },
          child: Container(
            height: 90 * scale,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(
              horizontal: 20 * scale,
              vertical: 15 * scale,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDFD),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1 * scale,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "BARANGAN BERBUNGKUS",
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1D1F),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right,
                  size: 24 * scale,
                  color: const Color(0xFF1A1D1F),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
