import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/navigation_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import 'register_view.dart';
import 'login_view.dart';
import 'edit_profile_view.dart';
import 'change_password_view.dart';

class ProfileView extends StatelessWidget {
  final double scale;

  const ProfileView({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Container(
      color: const Color(0xFFFFFDFD),
      child: Column(
        children: [
          // Profile Header Bar with Settings
          Container(
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
                if (authViewModel.isLoggedIn)
                  IconButton(
                    onPressed: () {
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
          ),
          Expanded(
            child: authViewModel.isLoggedIn
                ? _buildLoggedInUI(context, authViewModel)
                : _buildLoggedOutUI(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20 * scale),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1 * scale),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1 * scale)),
        titlePadding: EdgeInsets.fromLTRB(20 * scale, 15 * scale, 10 * scale, 0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.logout_rounded, color: const Color(0xFF1A1D1F), size: 20 * scale),
                SizedBox(width: 7 * scale),
                Text(
                  "LOGOUT",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16 * scale,
                    color: const Color(0xFF1A1D1F),
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close, color: const Color(0xFF1A1D1F), size: 20 * scale),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to log out?",
          style: TextStyle(
            fontSize: 14 * scale,
            color: const Color(0xFF1A1D1F),
          ),
        ),
        actionsPadding: EdgeInsets.fromLTRB(20 * scale, 10 * scale, 20 * scale, 20 * scale),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: const Color(0xFF1A1D1F),
                fontWeight: FontWeight.w600,
                fontSize: 14 * scale,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              viewModel.logout();
              Navigator.pop(context);
            },
            child: Text(
              "Confirm",
              style: TextStyle(
                color: const Color(0xFFED1A4B),
                fontWeight: FontWeight.w700,
                fontSize: 14 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInUI(BuildContext context, AuthViewModel viewModel) {
    final navViewModel = context.read<NavigationViewModel>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 25 * scale, vertical: 40 * scale),
      child: Column(
        children: [
          // User Information Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D1F),
              borderRadius: BorderRadius.circular(1 * scale),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 1 * scale,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.account_circle, color: const Color(0xFFFFFDFD), size: 60 * scale),
                SizedBox(width: 20 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.userName ?? 'User',
                        style: TextStyle(
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFFDFD),
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Text(
                        viewModel.userEmail ?? '',
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: const Color(0xFFFFFDFD),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 5 * scale),
          // Grid View for items
          GridView.count(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 5 * scale,
            mainAxisSpacing: 5 * scale,
            childAspectRatio: 1.0,
            children: [
              _buildGridItem(
                Icons.favorite_border_rounded,
                'Favourites',
                'Items you saved',
                () {
                  navViewModel.setSelectedIndex(1);
                },
              ),
              _buildGridItem(
                Icons.notifications_none_rounded,
                'Notifications',
                'Notify prices',
                () {},
              ),
              _buildGridItem(
                Icons.lock_reset_rounded,
                'Change Password',
                'Change security',
                () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangePasswordView(scale: scale),
                      )
                  );
                },
              ),
              _buildGridItem(
                Icons.assignment_late_outlined,
                'Complaints',
                'Submit an complaint',
                () {
                  navViewModel.setSelectedIndex(2);
                },
              ),
            ],
          ),

          SizedBox(height: 70 * scale),

          // Logout Button
          _buildButton(
            context,
            'LOGOUT',
            () => _showLogoutConfirmation(context, viewModel),
            Colors.white,
            const Color(0xFFED1A4B),
            isOutlined: true,
            icon: Icons.logout_rounded,
          ),

          SizedBox(height: 100 * scale), // Padding for bottom nav
        ],
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String title, String desc, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDFD),
            borderRadius: BorderRadius.circular(1 * scale),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
              width: 1 * scale,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D1F).withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF1A1D1F), size: 22 * scale),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D1F),
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11 * scale,
                  color: const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedOutUI(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton(
              context,
              'LOGIN',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginView(scale: scale),
                ),
              ),
              const Color(0xFF1A1D1F),
              Colors.white,
            ),
            SizedBox(height: 15 * scale),
            _buildButton(
              context,
              'REGISTER',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegisterView(scale: scale),
                ),
              ),
              Colors.white,
              const Color(0xFF1A1D1F),
              isOutlined: true,
            ),
            SizedBox(height: 20 * scale),
            Text(
              'Login first to view profile',
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1D1F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    VoidCallback onTap,
    Color bg,
    Color text, {
    bool isOutlined = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50 * scale,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: bg,
          foregroundColor: text,
          side: isOutlined
              ? BorderSide(color: text)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1 * scale),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20 * scale),
        ),
        child: Row(
          mainAxisAlignment: icon != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (icon != null) Icon(icon, size: 20 * scale),
          ],
        ),
      ),
    );
  }
}
