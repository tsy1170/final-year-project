import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_view_model.dart';
import '../widgets/common/animated_notification.dart';
import '../widgets/common/custom_button.dart';

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

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureCurrentPassword = true;

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
    _obscureCurrentPassword = true;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * widget.scale)),
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
                  obscureText: _obscureCurrentPassword,
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
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF1A1D1F),
                        size: 20 * widget.scale,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
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
          );
        },
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
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CHANGE PASSWORD',
          style: TextStyle(color: const Color(0xFF1A1D1F), fontSize: 16 * widget.scale, fontWeight: FontWeight.w700),
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
              obscureText: _obscureNewPassword,
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
                  borderRadius: BorderRadius.circular(12 * widget.scale),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12 * widget.scale),
                  borderSide: BorderSide(color: const Color(0xFF1A1D1F), width: 1 * widget.scale),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF1A1D1F),
                    size: 20 * widget.scale,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
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
              obscureText: _obscureConfirmPassword,
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
                  borderRadius: BorderRadius.circular(12 * widget.scale),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12 * widget.scale),
                  borderSide: BorderSide(color: const Color(0xFF325E6A), width: 1 * widget.scale),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF1A1D1F),
                    size: 20 * widget.scale,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
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
            CustomButton(
              label: "NEXT",
              onTap: _canSubmit ? _showPasswordDialog : () {},
              bg: const Color(0xFF1A1D1F).withValues(alpha: _canSubmit ? 1.0 : 0.5),
              text: Colors.white.withValues(alpha: _canSubmit ? 1.0 : 0.5),
              scale: widget.scale,
            ),
          ],
        ),
      ),
    );
  }
}
