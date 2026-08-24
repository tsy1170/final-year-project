import 'package:flutter/material.dart';
import '../../auth/edit_profile_view.dart';

class ProfileHeader extends StatelessWidget {
  final double scale;
  final bool isLoggedIn;
  final VoidCallback? onSettingsPressed;

  const ProfileHeader({
    super.key,
    required this.scale,
    required this.isLoggedIn,
    this.onSettingsPressed,
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
            'PROFILE',
            style: TextStyle(
              color: const Color(0xFF1A1D1F),
              fontSize: 22 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isLoggedIn)
            IconButton(
              onPressed: onSettingsPressed ?? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileView(scale: scale),
                  ),
                );
              },
              icon: Icon(
                Icons.settings_outlined,
                size: 24 * scale,
                color: const Color(0xFF1A1D1F),
              ),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
