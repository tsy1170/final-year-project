import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/navigation_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_user_card.dart';
import '../widgets/profile/profile_menu_item.dart';
import '../widgets/profile/profile_logged_out.dart';
import '../widgets/profile/logout_dialog.dart';
import '../widgets/common/custom_button.dart';
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
          ProfileHeader(
            scale: scale,
            isLoggedIn: authViewModel.isLoggedIn,
          ),
          Expanded(
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
          SizedBox(height: 5 * scale),
          GridView.count(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 5 * scale,
            mainAxisSpacing: 5 * scale,
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
                onTap: () {},
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
                onTap: () => navViewModel.setSelectedIndex(2),
                scale: scale,
              ),
            ],
          ),

          SizedBox(height: 70 * scale),

          CustomButton(
            label: 'LOGOUT',
            onTap: () => _showLogoutConfirmation(context, viewModel),
            bg: Colors.white,
            text: const Color(0xFFED1A4B),
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
