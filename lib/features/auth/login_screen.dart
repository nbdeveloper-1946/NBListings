import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nblistings/core/design_system/crm_design_system.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/dio_client.dart';
import 'package:dio/dio.dart';

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
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    showGeneralDialog(
      context: context,
      barrierColor: CRMColors.overlay,
      transitionDuration: CRMMotion.medium,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.r20),
          ),
          backgroundColor: CRMColors.surfaceElevated,
          title: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 28),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: Text(
                  title,
                  style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
          ),
          actionsPadding: const EdgeInsets.only(
            bottom: CRMSpacing.m,
            right: CRMSpacing.m,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: CRMColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Dismiss',
                style: CRMTypography.button.copyWith(color: CRMColors.primary),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: CRMMotion.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierColor: CRMColors.overlay,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.r20),
              ),
              backgroundColor: CRMColors.surfaceElevated,
              title: Text(
                'Forgot Password',
                style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter your email address below, and we will send a password reset request to your administrator.',
                      style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
                    ),
                    const SizedBox(height: CRMSpacing.md),
                    PremiumTextField(
                      controller: emailController,
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
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(
                bottom: CRMSpacing.m,
                right: CRMSpacing.m,
                left: CRMSpacing.m,
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: CRMColors.textSecondary,
                  ),
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: CRMTypography.button.copyWith(color: CRMColors.textSecondary),
                  ),
                ),
                const SizedBox(width: CRMSpacing.xs),
                CRMButton(
                  label: 'Submit',
                  isLoading: isSubmitting,
                  width: 120,
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            setState(() {
                              isSubmitting = true;
                            });
                            try {
                              final email = emailController.text.trim();
                              final response = await DioClient.dio.post(
                                '/auth/forgot-password',
                                data: {'email': email},
                              );
                              Navigator.pop(dialogContext);

                              showDialog(
                                context: context,
                                barrierColor: CRMColors.overlay,
                                builder: (context) => AlertDialog(
                                  backgroundColor: CRMColors.surfaceElevated,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(CRMBorderRadius.r20),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: CRMColors.primary,
                                        size: 28,
                                      ),
                                      const SizedBox(width: CRMSpacing.s),
                                      Text(
                                        'Request Sent',
                                        style: CRMTypography.sectionTitle.copyWith(
                                          color: CRMColors.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    response.data['message'] ??
                                        'Password reset request has been created successfully.',
                                    style: CRMTypography.body.copyWith(
                                      color: CRMColors.textSecondary,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Dismiss',
                                        style: CRMTypography.button.copyWith(
                                          color: CRMColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              setState(() {
                                isSubmitting = false;
                              });
                              String errorMsg = 'Failed to submit request. Please try again.';
                              if (e is DioException) {
                                errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: CRMColors.danger,
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
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

  BoxDecoration _panelDecoration({double radius = CRMBorderRadius.r24}) {
    return BoxDecoration(
      color: CRMColors.surfaceElevated,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: CRMColors.border.withOpacity(0.5),
        width: 0.5,
      ),
      boxShadow: CRMShadows.medium,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CRMColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showErrorDialog("Login Failed", state.message);
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Increase breakpoint to 950 to fit 1000px container and prevent test overflows at 800px width
              final isDesktop = constraints.maxWidth >= 950;

              if (isDesktop) {
                return Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(CRMSpacing.l),
                      child: SizedBox(
                        width: 1000,
                        height: 600,
                        child: Container(
                          decoration: _panelDecoration(),
                          clipBehavior: Clip.antiAlias,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildFormContent(isDesktop: true),
                              ),
                              const Expanded(
                                flex: 6,
                                child: _HeroSection(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              // Mobile Layout
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CRMSpacing.m,
                    vertical: CRMSpacing.l,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    decoration: _panelDecoration(radius: CRMBorderRadius.r20),
                    clipBehavior: Clip.antiAlias,
                    child: _buildFormContent(isDesktop: false),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent({required bool isDesktop}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Brand Logo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(CRMSpacing.xs),
                  decoration: BoxDecoration(
                    color: CRMColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                  ),
                  child: Icon(
                    Icons.cloud_queue_rounded,
                    color: CRMColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: CRMSpacing.s),
                Text(
                  'NB Listings',
                  style: CRMTypography.pageTitle.copyWith(
                    color: CRMColors.primary,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.xl),

            // Header Texts - Retain exact string "Go ahead to your account" for test assertion
            Text(
              'Go ahead to your account',
              style: CRMTypography.sectionTitle.copyWith(
                color: CRMColors.text,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: CRMSpacing.xs),
            Text(
              'Enter your credentials to access your account.',
              style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
            ),
            const SizedBox(height: CRMSpacing.xl),

            // Email input
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
            const SizedBox(height: CRMSpacing.md),

            // Password input
            PremiumTextField(
              controller: _passwordController,
              labelText: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: CRMSpacing.xs),
                child: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: CRMColors.primary.withOpacity(0.7),
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
            const SizedBox(height: CRMSpacing.s),

            // Remember Me & Forgot Password Row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: CRMSpacing.m,
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
                        activeColor: CRMColors.primary,
                        checkColor: CRMColors.surfaceElevated,
                        side: BorderSide(color: CRMColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CRMBorderRadius.xs + 2),
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
                      child: Text(
                        'Remember me',
                        style: CRMTypography.bodyMedium.copyWith(
                          color: CRMColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _showForgotPasswordDialog,
                    child: Text(
                      'Forgot Password?',
                      style: CRMTypography.bodyMedium.copyWith(
                        color: CRMColors.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.l),

            // Sign In Button
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return PremiumButton(
                  label: 'Sign In',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _WavePainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(
              'Treasure Of Listed Properties in Your Area',
              style: CRMTypography.largeTitle.copyWith(
                color: CRMColors.isDark ? CRMColors.text : const Color(0xFFF5F5F7),
                height: 1.25,
              ),
            ),
            const SizedBox(height: CRMSpacing.m),
            Text(
              'Manage pipeline boards, supply sheets, and builder agreements seamlessly.',
              style: CRMTypography.body.copyWith(
                color: CRMColors.isDark
                    ? CRMColors.textSecondary
                    : const Color(0xFFAEAEB2),
                height: 1.5,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          CRMColors.background,
          CRMColors.primary.withOpacity(0.85),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final wavePaint1 = Paint()
      ..color = CRMColors.primary.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.5);
    path1.quadraticBezierTo(
      size.width * 0.25, size.height * 0.35,
      size.width * 0.5, size.height * 0.55,
    );
    path1.quadraticBezierTo(
      size.width * 0.75, size.height * 0.75,
      size.width, size.height * 0.45,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, wavePaint1);

    final wavePaint2 = Paint()
      ..color = CRMColors.primary.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.quadraticBezierTo(
      size.width * 0.35, size.height * 0.8,
      size.width * 0.65, size.height * 0.5,
    );
    path2.quadraticBezierTo(
      size.width * 0.85, size.height * 0.35,
      size.width, size.height * 0.6,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, wavePaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
