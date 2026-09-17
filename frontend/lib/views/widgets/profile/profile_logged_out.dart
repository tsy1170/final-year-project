import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/auth_view_model.dart';
import '../../auth/login_view.dart';
import '../../auth/register_view.dart';
import '../common/custom_button.dart';
import '../common/animated_notification.dart';

class ProfileLoggedOut extends StatelessWidget {
  final double scale;

  const ProfileLoggedOut({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (authViewModel.isBiometricSupported && authViewModel.isBiometricEnabled) ...[
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () async {
                  // Capture overlay and scale before async call because this widget 
                  // will unmount immediately upon successful login.
                  final overlay = Overlay.of(context);
                  final currentScale = scale;
                  
                  final success = await authViewModel.loginWithBiometrics();
                  
                  if (success) {
                    showTopNotificationOnOverlay(overlay, "Login Successful!", true, currentScale);
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(20 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB85A3A).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 60 * scale,
                    color: const Color(0xFFB85A3A),
                  ),
                ),
              ),
              SizedBox(height: 10 * scale),
              Text(
                'Tap to login with biometrics',
                style: TextStyle(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB85A3A),
                ),
              ),
              SizedBox(height: 40 * scale),
              Row(
                children: [
                  Expanded(
                    child: Container(height: 1, color: Colors.grey.withOpacity(0.3)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15 * scale),
                    child: Text(
                      'OR',
                      style: TextStyle(fontSize: 12 * scale, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Container(height: 1, color: Colors.grey.withOpacity(0.3)),
                  ),
                ],
              ),
              SizedBox(height: 40 * scale),
            ],
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
              bg: const Color(0xFFF9ECE6),
              text: const Color(0xFFB85A3A),
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
