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
    final List<Map<String, dynamic>> categories = [
      {
        "name": "BARANGAN SEGAR",
        "icon": Icons.set_meal_outlined,
        "color": const Color(0xFFF7F5F0),
      },
      {
        "name": "BARANGAN KERING",
        "icon": Icons.bakery_dining_outlined,
        "color": const Color(0xFFF7F5F0),
      },
      {
        "name": "BARANGAN BERBUNGKUS",
        "icon": Icons.inventory_2_outlined,
        "color": const Color(0xFFF2F2F2),
      },
      {
        "name": "ITEM GROUPS",
        "icon": Icons.grid_view_rounded,
        "color": const Color(0xFFFBF8F5),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(30 * scale, 40 * scale, 20 * scale, 17 * scale),
          child: Text(
            "CATEGORIES",
            style: TextStyle(
              fontSize: 15 * scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1D1F),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * scale),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10 * scale,
              mainAxisSpacing: 10 * scale,
              childAspectRatio: 1.5,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemGroupsView(
                        scale: scale,
                        initialExpandedGroup: index == 3 ? null : cat['name'],
                      ),
                    ),
                  );
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative Icon Background
                      Positioned(
                        right: -10 * scale,
                        bottom: -12 * scale,
                        child: Icon(
                          cat['icon'],
                          size: 70 * scale,
                          color: const Color(0xFF1A1D1F).withValues(alpha: 0.03),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(15 * scale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(8 * scale),
                              decoration: BoxDecoration(
                                color: cat['color'],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                cat['icon'],
                                size: 18 * scale,
                                color: const Color(0xFF1A1D1F),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              cat['name'],
                              style: TextStyle(
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A1D1F),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
