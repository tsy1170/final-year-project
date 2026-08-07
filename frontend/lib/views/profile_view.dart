import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/grocery_view_model.dart';
import 'register_view.dart';
import 'login_view.dart';

class ProfileView extends StatelessWidget {
  final double scale;

  const ProfileView({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroceryViewModel>();

    return Container(
      color: const Color(0xFFFFFDFD),
      child: Column(
        children: [
          // Profile Header Bar
          Container(
            width: double.infinity,
            // height: 100 * scale,
            padding: EdgeInsets.only(
              top: 45 * scale,
              left: 20 * scale,
              bottom: 15 * scale,
            ),
            alignment: Alignment.topLeft,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDFD),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1 * scale,
                ),
              ),
            ),
            child: Text(
              'PROFILE',
              style: TextStyle(
                color: const Color(0xFF1A1D1F),
                fontSize: 24 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: viewModel.isLoggedIn
                ? _buildLoggedInUI(context, viewModel)
                : _buildLoggedOutUI(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInUI(BuildContext context, GroceryViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle,
            size: 80 * scale,
            color: const Color(0xFF1A1D1F),
          ),
          SizedBox(height: 20 * scale),
          Text(
            'Welcome, ${viewModel.userName}',
            style: TextStyle(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D1F),
            ),
          ),
          SizedBox(height: 5 * scale),
          Text(
            '${viewModel.userEmail}',
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1D1F).withOpacity(0.5),
            ),
          ),
          SizedBox(height: 40 * scale),
          _buildButton(
            context,
            'Logout',
            () => viewModel.logout(),
            const Color(0xFFED1A4B),
            Colors.white,
          ),
        ],
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
                letterSpacing: 0
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
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50 * scale,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: text,
          elevation: 0,
          side: isOutlined
              ? const BorderSide(color: Color(0xFF1A1D1F))
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1 * scale),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
