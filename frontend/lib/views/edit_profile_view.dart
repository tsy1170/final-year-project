import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import 'change_email_view.dart';
import 'change_password_view.dart';
import 'widgets/common/animated_notification.dart';

class EditProfileView extends StatefulWidget {
  final double scale;
  const EditProfileView({super.key, required this.scale});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late TextEditingController _usernameController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final authViewModel = context.read<AuthViewModel>();
    _usernameController = TextEditingController(text: authViewModel.userName);
    _usernameController.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    final authViewModel = context.read<AuthViewModel>();
    setState(() {
      _hasChanges = _usernameController.text != authViewModel.userName;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final authViewModel = context.read<AuthViewModel>();
    try {
      await authViewModel.updateUsername(_usernameController.text);
      if (mounted) {
        showTopNotification(context, "Username updated successfully", true, widget.scale);
        setState(() {
          _hasChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showTopNotification(context, e.toString().replaceFirst('Exception: ', ''), false, widget.scale);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDFD),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'EDIT PROFILE',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 16 * widget.scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: authViewModel.isUpdating ? null : _saveUsername,
              child: authViewModel.isUpdating
                  ? SizedBox(
                      width: 15 * widget.scale,
                      height: 15 * widget.scale,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1D1F)),
                    )
                  : Icon(Icons.save_as, color: const Color(0xFF1A1D1F), size: 25 * widget.scale)
            ),
          SizedBox(width: 10 * widget.scale),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20 * widget.scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Username'),
            _buildTextField(
              controller: _usernameController,
              hint: 'Enter username',
              icon: Icons.person_outline_rounded,
            ),
            SizedBox(height: 20 * widget.scale),
            _buildSectionTitle('Email'),
            _buildRedirectBox(
              label: authViewModel.userEmail ?? '',
              icon: Icons.email_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangeEmailView(scale: widget.scale)),
              ),
            ),
            SizedBox(height: 20 * widget.scale),
            _buildSectionTitle('Password'),
            _buildRedirectBox(
              label: '********',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordView(scale: widget.scale)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * widget.scale, left: 5 * widget.scale),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14 * widget.scale,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1D1F),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(1 * widget.scale),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 14 * widget.scale, fontWeight: FontWeight.w400),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF1A1D1F), size: 18 * widget.scale),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15 * widget.scale),
        ),
      ),
    );
  }

  Widget _buildRedirectBox({required String label, required IconData icon, bool isPassword = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15 * widget.scale, vertical: 15 * widget.scale),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(1 * widget.scale),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
            SizedBox(width: 17 * widget.scale),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14 * widget.scale,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1A1D1F),
                ),
              ),
            ),
            Icon(Icons.edit_outlined, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
          ],
        ),
      ),
    );
  }
}
