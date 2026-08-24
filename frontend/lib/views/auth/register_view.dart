import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_view_model.dart';
import '../widgets/common/animated_notification.dart';
import 'login_view.dart';

class RegisterView extends StatefulWidget {
  final double scale;

  const RegisterView({super.key, required this.scale});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _selectedDob;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              dividerColor: Colors.grey.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(1 * widget.scale),
              ),
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFFFFFDFD)),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A1D1F),
              onPrimary: Color(0xFFFFFDFD),
              onSurface: Color(0xFF1A1D1F),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = context.read<AuthViewModel>();
      try {
        final success = await authViewModel.register(
          name: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim(),
          dob: _dobController.text.trim(),
        );

        if (mounted) {
          if (success) {
            showTopNotification(context, "Registration Successful! Please login.", true, widget.scale);
            // Redirect to Login page after successful registration
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginView(scale: widget.scale)),
            );
          } else {
            showTopNotification(context, "Registration Failed. Please try again.", false, widget.scale);
          }
        }
      } catch (e) {
        if (mounted) {
          // Display the specific error message
          final errorMsg = e.toString().replaceFirst('Exception: ', '');
          showTopNotification(context, errorMsg, false, widget.scale);
        }
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
          'Register',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 18 * widget.scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(25 * widget.scale),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Username"),
              _buildTextField(
                controller: _usernameController,
                hint: "Enter your username",
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter username";
                  if (value.length < 2) return "Username too short";
                  return null;
                },
              ),
              SizedBox(height: 20 * widget.scale),
              _buildLabel("Email"),
              _buildTextField(
                controller: _emailController,
                hint: "Enter your email",
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter email";
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return "Enter a valid email";
                  return null;
                },
              ),
              SizedBox(height: 20 * widget.scale),
              _buildLabel("Phone Number"),
              _buildTextField(
                controller: _phoneController,
                hint: "Enter your phone number",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter phone number";
                  return null;
                },
              ),
              SizedBox(height: 20 * widget.scale),
              _buildLabel("Date of Birth"),
              _buildTextField(
                controller: _dobController,
                hint: "Select your date of birth",
                readOnly: true,
                suffixIcon: Icon(Icons.calendar_today, size: 18 * widget.scale, color: const Color(0xFF1A1D1F)),
                onTap: () => _selectDob(context),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please select date of birth";
                  return null;
                },
              ),
              SizedBox(height: 20 * widget.scale),
              _buildLabel("Password"),
              _buildTextField(
                controller: _passwordController,
                hint: "Enter your password",
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20 * widget.scale),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter password";
                  if (value.length < 8) return "Password must be at least 8 characters";
                  return null;
                },
              ),
              SizedBox(height: 20 * widget.scale),
              _buildLabel("Confirm Password"),
              _buildTextField(
                controller: _confirmPasswordController,
                hint: "Re-enter your password",
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 20 * widget.scale),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                validator: (value) {
                  if (value != _passwordController.text) return "Passwords do not match";
                  return null;
                },
              ),
              SizedBox(height: 40 * widget.scale),
              authViewModel.isRegistering
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1D1F)))
                  : SizedBox(
                      width: double.infinity,
                      height: 55 * widget.scale,
                      child: ElevatedButton(
                        onPressed: _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1D1F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1 * widget.scale)),
                          elevation: 0,
                        ),
                        child: Text(
                          "Register",
                          style: TextStyle(color: Colors.white, fontSize: 16 * widget.scale, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
              SizedBox(height: 20 * widget.scale),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginView(scale: widget.scale)),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Already Have Account?  ",
                      style: TextStyle(
                        color: const Color(0xFF1A1D1F),
                        fontSize: 14 * widget.scale,
                        fontFamily: 'Montserrat',
                      ),
                      children: [
                        TextSpan(
                          text: "Login",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D1F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30 * widget.scale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * widget.scale),
      child: Text(
        text,
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
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(fontSize: 14 * widget.scale, color: const Color(0xFF1A1D1F)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF9A9FA5), fontSize: 12 * widget.scale),
        filled: true,
        fillColor: const Color(0xFFF4F4F4),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1 * widget.scale),
          borderSide: BorderSide(color: const Color(0xFF1A1D1F), width: 1 * widget.scale),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1 * widget.scale),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16 * widget.scale, vertical: 16 * widget.scale),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
