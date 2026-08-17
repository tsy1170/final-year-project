import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import 'widgets/common/animated_notification.dart';

class ChangeEmailView extends StatefulWidget {
  final double scale;
  const ChangeEmailView({super.key, required this.scale});

  @override
  State<ChangeEmailView> createState() => _ChangeEmailViewState();
}

class _ChangeEmailViewState extends State<ChangeEmailView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _showPasswordDialog() {
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1 * widget.scale)),
        title: Text(
          "Current Password",
          style: TextStyle(fontSize: 18 * widget.scale, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Please enter your current password to confirm the email change.",
              style: TextStyle(fontSize: 14 * widget.scale),
            ),
            SizedBox(height: 20 * widget.scale),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Password",
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
      await authViewModel.updateEmail(_emailController.text, _passwordController.text);
      if (mounted) {
        showTopNotification(context, "Email updated. Please login again.", true, widget.scale);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        showTopNotification(context, e.toString().replaceFirst('Exception: ', ''), false, widget.scale);
      }
    }
  }

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
          'CHANGE EMAIL',
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
              "Enter your new email address. You will be logged out and need to log in again.",
              style: TextStyle(fontSize: 14 * widget.scale, color: const Color(0xFF1A1D1F)),
            ),
            SizedBox(height: 20 * widget.scale),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(fontSize: 14 * widget.scale, color: const Color(0xFF1A1D1F)),
              decoration: InputDecoration(
                hintText: "New Email",
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
            SizedBox(height: 20 * widget.scale),
            SizedBox(
              width: double.infinity,
              height: 50 * widget.scale,
              child: ElevatedButton(
                onPressed: _emailController.text.isNotEmpty ? _showPasswordDialog : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1D1F),
                  disabledBackgroundColor: const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1 * widget.scale)),
                ),
                child: Text("NEXT", style: TextStyle(color: Colors.white.withValues(alpha: _emailController.text.isNotEmpty ? 1.0 : 0.5), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
