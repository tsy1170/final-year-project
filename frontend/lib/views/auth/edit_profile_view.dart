import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_view_model.dart';
import 'change_email_view.dart';
import 'change_password_view.dart';
import '../widgets/common/animated_notification.dart';

class EditProfileView extends StatefulWidget {
  final double scale;
  const EditProfileView({super.key, required this.scale});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final authViewModel = context.read<AuthViewModel>();
    _usernameController = TextEditingController(text: authViewModel.userName ?? '');
    _phoneController = TextEditingController(text: authViewModel.userPhoneNumber ?? '');
    _dobController = TextEditingController(text: authViewModel.userDob ?? '');
    
    _usernameController.addListener(_onProfileChanged);
    _phoneController.addListener(_onProfileChanged);
    _dobController.addListener(_onProfileChanged);
  }

  void _onProfileChanged() {
    final authViewModel = context.read<AuthViewModel>();
    setState(() {
      _hasChanges = _usernameController.text != (authViewModel.userName ?? '') ||
          _phoneController.text != (authViewModel.userPhoneNumber ?? '') ||
          _dobController.text != (authViewModel.userDob ?? '');
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDob(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(_dobController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A1D1F),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1D1F),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    final authViewModel = context.read<AuthViewModel>();
    try {
      // Update Username if changed
      if (_usernameController.text != (authViewModel.userName ?? '')) {
        await authViewModel.updateUsername(_usernameController.text);
      }
      
      // Update Phone Number if changed
      if (_phoneController.text != (authViewModel.userPhoneNumber ?? '')) {
        await authViewModel.updatePhoneNumber(_phoneController.text);
      }
      
      // Update DOB if changed
      if (_dobController.text != (authViewModel.userDob ?? '')) {
        await authViewModel.updateDob(_dobController.text);
      }

      if (mounted) {
        showTopNotification(context, "Profile updated successfully", true, widget.scale);
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1 * widget.scale),
          child: Divider(height: 1 * widget.scale, color: Colors.grey.withValues(alpha: 0.2)),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: authViewModel.isUpdating ? null : _saveProfile,
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
            _buildSectionTitle('Phone Number'),
            _buildTextField(
              controller: _phoneController,
              hint: 'Enter phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SizedBox(height: 20 * widget.scale),
            _buildSectionTitle('Date of Birth'),
            _buildTextField(
              controller: _dobController,
              hint: 'Select date of birth',
              icon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: () => _selectDob(context),
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

  Widget _buildTextField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(1 * widget.scale),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(fontSize: 14 * widget.scale, fontWeight: FontWeight.w400),
        decoration: InputDecoration(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(1 * widget.scale),
            borderSide: BorderSide(color: const Color(0xFF1A1D1F), width: 1 * widget.scale),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15 * widget.scale),
            child: Icon(icon, color: const Color(0xFF1A1D1F), size: 18 * widget.scale),
          ),
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
        width: double.infinity,
        child: InputDecorator(
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15 * widget.scale),
              child: Icon(icon, color: const Color(0xFF1A1D1F), size: 18 * widget.scale),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1 * widget.scale),
              borderSide: BorderSide.none
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 15 * widget.scale),
            filled: true,
            fillColor: const Color(0xFFF4F4F4),
          ),
          child: Row(
            children: [
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
              Padding(
                padding: EdgeInsets.only(right: 15 * widget.scale),
                child: Icon(Icons.edit_outlined, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
              ),
            ],
          ),
        )
      )
    );
  }
}
