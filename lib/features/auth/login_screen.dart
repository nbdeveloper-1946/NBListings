import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
          ),
          backgroundColor: const Color(0xFF1E293B),
          title: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 15,
            ),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.indigoAccent.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      context.read<AuthBloc>().add(
        LoginSubmitted(email: email, password: password, rememberMe: _rememberMe),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 72,
        leading: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: InkWell(
              onTap: () {
                context.go('/splash');
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showErrorDialog("Login Failed", state.message);
          }
        },
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Logo with glowing cyan accent
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft cyan glow behind the logo
                        Container(
                          width: 140,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x1F00E5FF),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/images/NB-listings-logo.png',
                          height: 115,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.blur_on_rounded,
                              size: 60,
                              color: Colors.white,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Header texts
                  const Center(
                    child: Text(
                      'Go ahead to your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // White card container with premium design system
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(AppBorderRadius.card),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1.5,
                      ),
                      boxShadow: AppShadows.premiumCard,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Reusable Premium Input Field (Email)
                          PremiumTextField(
                            controller: _emailController,
                            labelText: 'Email Address',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email address';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: AppSpacing.ml),

                          // Reusable Premium Input Field (Password)
                          PremiumTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.brandGreen.withOpacity(0.7),
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: AppSpacing.m),

                          // Remember Me & Forgot Password Row
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            runSpacing: 10,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.brandGreen,
                                      checkColor: Colors.white,
                                      side: const BorderSide(color: AppColors.inputBorder, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    child: const Text(
                                      'Remember me',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    // Forgot password action
                                  },
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: AppColors.brandGreen,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Reusable Premium Button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;
                              return PremiumButton(
                                label: 'Login',
                                isLoading: isLoading,
                                onPressed: isLoading ? null : _submit,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Footer Text
                  Center(
                    child: Text(
                      '@2026 NB Realty all rights are reserved',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}