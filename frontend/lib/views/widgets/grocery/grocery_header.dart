import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/grocery_view_model.dart';
import '../../../viewmodels/navigation_view_model.dart';
import '../../grocery/search_page_view.dart';
import '../../grocery/item_groups_view.dart';
import '../../price_alert/price_alerts_view.dart';

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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(15),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 140 * scale,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(15),
            ),
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
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PriceAlertsView(scale: scale),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20 * scale),
                        child: Padding(
                          padding: EdgeInsets.all(4 * scale),
                          child: Icon(
                            Icons.notifications_outlined,
                            size: 24 * scale,
                            color: const Color(0xFF1A1D1F),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * scale),
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
              Positioned(
                left: 20 * scale,
                right: 20 * scale,
                top: 85 * scale,
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
                            borderRadius: BorderRadius.circular(20 * scale),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                              width: 1 * scale,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 10 * scale),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 20 * scale,
                                  color: const Color(0xFFB85A3A),
                                ),
                                SizedBox(width: 12 * scale),
                                Text(
                                  'Search Items',
                                  style: TextStyle(
                                    fontSize: 12 * scale,
                                    color: const Color(0xFF1A1D1F).withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
