import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import 'widgets/common/animated_notification.dart';

class ChangePasswordView extends StatefulWidget {
  final double scale;
  const ChangePasswordView({super.key, required this.scale});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  void _showPasswordDialog() {
    // Clear the current password field before showing the dialog
    _currentPasswordController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1 * widget.scale)),
        title: Text(
          "Confirm Identity",
          style: TextStyle(fontSize: 18 * widget.scale, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Please enter your current password to confirm the password change.",
              style: TextStyle(fontSize: 14 * widget.scale),
            ),
            SizedBox(height: 20 * widget.scale),
            TextField(
              style: TextStyle(fontSize: 14 * widget.scale, color: const Color(0xFF1A1D1F)),
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Current Password",
                hintStyle: TextStyle(
                    color: const Color(0xFF9A9FA5),
                    fontSize: 12 * widget.scale
                ),
                filled: true,
                fillColor: const Color(0xFFF4F4F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(1 * widget.scale),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitChange();
            },
            child: const Text("CONFIRM", style: TextStyle(color: Color(0xFF1A1D1F), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitChange() async {
    final authViewModel = context.read<AuthViewModel>();
    try {
      await authViewModel.updatePassword(_newPasswordController.text, _currentPasswordController.text);
      if (mounted) {
        showTopNotification(context, "Password updated successfully. Please login again.", true, widget.scale);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        showTopNotification(context, e.toString().replaceFirst('Exception: ', ''), false, widget.scale);
      }
    }
  }

  bool get _isPasswordValid => _newPasswordController.text.length >= 8;
  bool get _doPasswordsMatch => _newPasswordController.text == _confirmPasswordController.text;
  bool get _canSubmit => _isPasswordValid && _doPasswordsMatch && _confirmPasswordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDFD),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CHANGE PASSWORD',
          style: TextStyle(color: const Color(0xFF1A1D1F), fontSize: 16 * widget.scale, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1 * widget.scale),
          child: Divider(height: 1 * widget.scale, color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20 * widget.scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter your new password. You will be logged out and need to log in again.",
              style: TextStyle(fontSize: 14 * widget.scale, color: const Color(0xFF1A1D1F)),
            ),
            SizedBox(height: 20 * widget.scale),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 14 * widget.scale, color: const Color(0xFF1A1D1F)),
              decoration: InputDecoration(
                hintText: "New Password",
                hintStyle: TextStyle(
                    color: const Color(0xFF9A9FA5),
                    fontSize: 12 * widget.scale
                ),
                filled: true,
                fillColor: const Color(0xFFF4F4F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(1 * widget.scale),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0 * widget.scale),
              child: Text(
                _newPasswordController.text.isNotEmpty && !_isPasswordValid
                    ? "Password must be at least 8 characters"
                    : "Password must at least 8-digit",
                style: TextStyle(
                  fontSize: 12 * widget.scale,
                  color: _newPasswordController.text.isNotEmpty && !_isPasswordValid
                      ? Colors.red
                      : const Color(0xFF9A9FA5),
                ),
              ),
            ),
            SizedBox(height: 20 * widget.scale),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 14 * widget.scale, color: const Color(0xFF1A1D1F)),
              decoration: InputDecoration(
                hintText: "Confirm Password",
                hintStyle: TextStyle(
                    color: const Color(0xFF9A9FA5),
                    fontSize: 12 * widget.scale
                ),
                filled: true,
                fillColor: const Color(0xFFF4F4F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(1 * widget.scale),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_confirmPasswordController.text.isNotEmpty && !_doPasswordsMatch)
              Padding(
                padding: EdgeInsets.only(top: 8.0 * widget.scale),
                child: Text(
                  "Passwords do not match",
                  style: TextStyle(fontSize: 12 * widget.scale, color: Colors.red),
                ),
              ),
            SizedBox(height: 20 * widget.scale),
            SizedBox(
              width: double.infinity,
              height: 50 * widget.scale,
              child: ElevatedButton(
                onPressed: _canSubmit ? _showPasswordDialog : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1D1F),
                  disabledBackgroundColor: const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1 * widget.scale)),
                ),
                child: Text(
                  "NEXT",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: _canSubmit ? 1.0 : 0.5),
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
