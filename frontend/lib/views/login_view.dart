import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import 'widgets/common/animated_notification.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  final double scale;

  const LoginView({super.key, required this.scale});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = context.read<AuthViewModel>();
      try {
        final success = await authViewModel.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted && success) {
          showTopNotification(context, "Login Successful!", true, widget.scale);
          Navigator.pop(context); // Back to ProfileView which will now show logged in UI
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = e.toString().replaceFirst('Exception: ', '');
          showTopNotification(context, errorMsg, false, widget.scale);
        }
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
          'Login',
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
                  return null;
                },
              ),
              SizedBox(height: 40 * widget.scale),
              context.watch<AuthViewModel>().isLoggingIn
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1D1F)))
                  : SizedBox(
                      width: double.infinity,
                      height: 55 * widget.scale,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1D1F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1 * widget.scale)),
                          elevation: 0,
                        ),
                        child: Text(
                          "Login",
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
                      MaterialPageRoute(builder: (context) => RegisterView(scale: widget.scale)),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't Have Account?  ",
                      style: TextStyle(
                        color: const Color(0xFF1A1D1F),
                        fontSize: 14 * widget.scale,
                        fontFamily: 'Montserrat',
                      ),
                      children: [
                        TextSpan(
                          text: "Register Now",
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
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: 14 * widget.scale, color: const Color(0xFF1A1D1F)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF9A9FA5), fontSize: 12 * widget.scale),
        filled: true,
        fillColor: const Color(0xFFF4F4F4),
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
