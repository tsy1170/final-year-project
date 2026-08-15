import 'package:flutter/material.dart';
import '../../item_groups_view.dart';

class FavouriteHeader extends StatelessWidget {
  final double scale;
  final bool isLoggedIn;

  const FavouriteHeader({
    super.key,
    required this.scale,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 90 * scale,
      padding: EdgeInsets.only(
        top: 40 * scale,
        left: 20 * scale,
        right: 20 * scale,
        bottom: 10 * scale,
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
            'FAVOURITES',
            style: TextStyle(
              color: const Color(0xFF1A1D1F),
              fontSize: 21 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isLoggedIn)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemGroupsView(scale: scale),
                  ),
                );
              },
              icon: Icon(
                Icons.add_circle_outline_rounded,
                size: 26 * scale,
                color: const Color(0xFF1A1D1F),
              ),
            ),
        ],
      ),
    );
  }
}
