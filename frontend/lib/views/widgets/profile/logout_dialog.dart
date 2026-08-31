import 'package:flutter/material.dart';
import '../../../viewmodels/auth_view_model.dart';

class LogoutDialog extends StatelessWidget {
  final double scale;
  final AuthViewModel viewModel;

  const LogoutDialog({
    super.key,
    required this.scale,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20 * scale),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * scale),
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
    );
  }
}
