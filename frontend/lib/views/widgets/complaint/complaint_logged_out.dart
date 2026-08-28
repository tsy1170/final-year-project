import 'package:flutter/material.dart';
import '../../auth/login_view.dart';
import '../common/custom_button.dart';

class ComplaintLoggedOutState extends StatelessWidget {
  final double scale;

  const ComplaintLoggedOutState({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 50 * scale,
              color: const Color(0xFF1A1D1F).withValues(alpha: 0.2),
            ),
            SizedBox(height: 20 * scale),
            Text(
              'Login to see your complaints',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1D1F),
              ),
            ),
            SizedBox(height: 25 * scale),
            CustomButton(
              label: 'LOGIN',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginView(scale: scale)),
                );
              },
              bg: const Color(0xFF1A1D1F),
              text: Colors.white,
              scale: scale,
            ),
          ],
        ),
      ),
    );
  }
}
