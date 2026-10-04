import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_view_model.dart';
import '../widgets/common/animated_notification.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/mesh_background.dart';
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
          
          if (authViewModel.isBiometricSupported && !authViewModel.isBiometricEnabled) {
            await _showBiometricPrompt(authViewModel);
          }
          
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = e.toString().replaceFirst('Exception: ', '');
          showTopNotification(context, errorMsg, false, widget.scale);
        }
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authViewModel = context.read<AuthViewModel>();
    try {
      final success = await authViewModel.loginWithBiometrics();
      if (mounted && success) {
        showTopNotification(context, "Login Successful!", true, widget.scale);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showTopNotification(context, "Biometric authentication failed", false, widget.scale);
      }
    }
  }

  Future<void> _showBiometricPrompt(AuthViewModel authViewModel) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * widget.scale)),
        title: Text("Enable Biometrics", style: TextStyle(fontSize: 18 * widget.scale, fontWeight: FontWeight.bold, color: const Color(0xFF1A1D1F))),
        content: Text("Would you like to enable biometric login for faster access next time?", style: TextStyle(fontSize: 14 * widget.scale, color: const Color(0xFF1A1D1F))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Later", style: TextStyle(color: const Color(0xFF9A9FA5), fontSize: 14 * widget.scale, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authViewModel.enableBiometrics();
            },
            child: Text("Enable", style: TextStyle(color: const Color(0xFFB85A3A), fontWeight: FontWeight.bold, fontSize: 14 * widget.scale)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE4),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'LOGIN',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 18 * widget.scale,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: MeshBackground()),
          SafeArea(
            bottom: true,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20 * widget.scale),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 30 * widget.scale),
                    Container(
                      padding: EdgeInsets.all(25 * widget.scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24 * widget.scale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
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
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20 * widget.scale, color: const Color(0xFF1A1D1F)),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return "Please enter password";
                              return null;
                            },
                          ),
                          SizedBox(height: 30 * widget.scale),
                          authViewModel.isLoggingIn
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1D1F)))
                              : Row(
                                  children: [
                                    Expanded(
                                      child: CustomButton(
                                        label: "LOGIN",
                                        onTap: _handleLogin,
                                        bg: const Color(0xFF1A1D1F),
                                        text: Colors.white,
                                        scale: widget.scale,
                                      ),
                                    ),
                                    if (authViewModel.isBiometricSupported && authViewModel.isBiometricEnabled) ...[
                                      SizedBox(width: 12 * widget.scale),
                                      InkWell(
                                        onTap: _handleBiometricLogin,
                                        child: Container(
                                          height: 50 * widget.scale,
                                          width: 50 * widget.scale,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF6F3),
                                            borderRadius: BorderRadius.circular(12 * widget.scale),
                                            border: Border.all(color: const Color(0xFFB85A3A).withOpacity(0.2), width: 1),
                                          ),
                                          child: Icon(Icons.fingerprint_rounded, color: const Color(0xFFB85A3A), size: 30 * widget.scale),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        ],
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
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: "Register Now",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB85A3A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 50 * widget.scale),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * widget.scale, left: 5 * widget.scale),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13 * widget.scale,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF9A9FA5),
          letterSpacing: 0.3,
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
      style: TextStyle(fontSize: 14 * widget.scale, color: const Color(0xFF1A1D1F), fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF9A9FA5).withOpacity(0.6), fontSize: 11 * widget.scale, fontWeight: FontWeight.w400),
        filled: true,
        fillColor: const Color(0xFFF7F5F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * widget.scale),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * widget.scale),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * widget.scale),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * widget.scale),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20 * widget.scale, vertical: 18 * widget.scale),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
