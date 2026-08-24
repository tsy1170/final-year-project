import 'package:flutter/material.dart';
import '../../auth/login_view.dart';
import '../../auth/register_view.dart';
import '../common/custom_button.dart';

class ProfileLoggedOut extends StatelessWidget {
  final double scale;

  const ProfileLoggedOut({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomButton(
              label: 'LOGIN',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginView(scale: scale),
                ),
              ),
              bg: const Color(0xFF1A1D1F),
              text: Colors.white,
              scale: scale,
            ),
            SizedBox(height: 15 * scale),
            CustomButton(
              label: 'REGISTER',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegisterView(scale: scale),
                ),
              ),
              bg: Colors.white,
              text: const Color(0xFF1A1D1F),
              isOutlined: true,
              scale: scale,
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
}
