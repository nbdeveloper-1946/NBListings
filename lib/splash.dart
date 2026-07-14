import 'package:flutter/material.dart';
import 'features/auth/login_screen.dart';
import 'core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 960) {
            return _buildLaptopLayout(context, constraints);
          } else {
            return _buildMobileLayout(context, constraints);
          }
        },
      ),
    );
  }

  // Beautiful Laptop/Desktop Split-Visual Layout
  Widget _buildLaptopLayout(BuildContext context, BoxConstraints constraints) {
    return Stack(
      children: [
        // Full screen background image, shifted to align the tower on the right side
        Positioned.fill(
          child: Image.asset(
            'assets/images/nbbg.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0.4, 0.0),
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.darkSlate,
                child: const Center(
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 150,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),

        // Elegant gradient fading to solid dark slate on the left side
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.darkBg, // Solid dark slate/black on left
                  Color(0xF2090D16), // 95% opacity
                  Color(0xBF090D16), // 75% opacity
                  Color(0x00090D16), // Fully transparent on the right
                ],
                stops: [0.0, 0.4, 0.65, 1.0],
              ),
            ),
          ),
        ),

        // Left-aligned Content
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth * 0.08, // Responsive side padding
              vertical: AppSpacing.xxl,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Tag/Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppBorderRadius.tag),
                        border: Border.all(
                          color: AppColors.brandGreen.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'PREMIUM REAL ESTATE',
                        style: TextStyle(
                          color: Color(0xff8BB39B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Big Elegant Title Typography
                    const Text(
                      'Treasure of listed\nproperties in your area',
                      style: AppTextStyles.display,
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Subtitle
                    const Text(
                      'Find your dream home effortlessly. The ultimate real estate platform designed to streamline your property search and connect you with top listings.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 17,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Unified Premium Design System Button
                    PremiumButton(
                      label: 'Get Started',
                      width: 220,
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Premium Mobile Bottom-Faded Stack Layout
  Widget _buildMobileLayout(BuildContext context, BoxConstraints constraints) {
    return Stack(
      children: [
        // Full screen background image
        Positioned.fill(
          child: Image.asset(
            'assets/images/nbbg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.darkSlate,
                child: const Center(
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 150,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),

        // Dark gradient overlay from top to bottom (solid black at bottom)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33090D16), // 20% opacity at top
                  Color(0xCC090D16), // 80% opacity
                  AppColors.darkBg,  // 100% opacity at bottom
                ],
                stops: [0.0, 0.5, 0.85],
              ),
            ),
          ),
        ),

        // Content positioned at the bottom
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Premium Tag/Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppBorderRadius.tag),
                        border: Border.all(
                          color: AppColors.brandGreen.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'PREMIUM REAL ESTATE',
                        style: TextStyle(
                          color: Color(0xff8BB39B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Title
                    const Text(
                      'Treasure of listed\nproperties in your area',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Subtitle
                    const Text(
                      'Find your dream home effortlessly. The ultimate real estate platform designed to streamline your property search.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Unified Premium Design System Button
                    PremiumButton(
                      label: 'Get Started',
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.s),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}