import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/navigation_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../widgets/profile/profile_user_card.dart';
import '../widgets/profile/profile_menu_item.dart';
import '../widgets/profile/profile_logged_out.dart';
import '../widgets/profile/logout_dialog.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/mesh_background.dart';
import 'change_password_view.dart';
import 'edit_profile_view.dart';
import '../price_alert/price_alerts_view.dart';

class ProfileView extends StatelessWidget {
  final double scale;

  const ProfileView({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'PROFILE',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 18 * scale,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5
          ),
        ),
        actions: [
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
                color: const Color(0xFFB85A3A),
              ),
            ),
          SizedBox(width: 10 * scale),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: MeshBackground()),
          SafeArea(
            child: authViewModel.isLoggedIn
                ? _buildLoggedInUI(context, authViewModel)
                : ProfileLoggedOut(scale: scale),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => LogoutDialog(
        scale: scale,
        viewModel: viewModel,
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
          ProfileUserCard(
            userName: viewModel.userName,
            userEmail: viewModel.userEmail,
            scale: scale,
          ),
          SizedBox(height: 10 * scale),
          GridView.count(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10 * scale,
            mainAxisSpacing: 10 * scale,
            childAspectRatio: 1.0,
            children: [
              ProfileMenuItem(
                icon: Icons.favorite_border_rounded,
                title: 'Favourites',
                desc: 'Items you saved',
                onTap: () => navViewModel.setSelectedIndex(1),
                scale: scale,
              ),
              ProfileMenuItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                desc: 'Notify prices',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PriceAlertsView(scale: scale),
                    ),
                  );
                },
                scale: scale,
              ),
              ProfileMenuItem(
                icon: Icons.lock_reset_rounded,
                title: 'Change Password',
                desc: 'Change security',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordView(scale: scale),
                    ),
                  );
                },
                scale: scale,
              ),
              ProfileMenuItem(
                icon: Icons.assignment_late_outlined,
                title: 'Complaints',
                desc: 'Submit a complaint',
                onTap: () => navViewModel.setSelectedIndex(3),
                scale: scale,
              ),
            ],
          ),
          SizedBox(height: 70 * scale),
          CustomButton(
            label: 'LOGOUT',
            onTap: () => _showLogoutConfirmation(context, viewModel),
            bg: const Color(0xFFF9ECE6), // Soft terracotta tinted pill
            text: const Color(0xFFB85A3A),
            isOutlined: true,
            icon: Icons.logout_rounded,
            scale: scale,
          ),
          SizedBox(height: 100 * scale), // Padding for bottom nav
        ],
      ),
    );
  }
}
