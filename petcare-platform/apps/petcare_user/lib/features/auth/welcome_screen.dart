import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/petcare_button.dart';
import 'phone_login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Minimal Brand Mark
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: PetColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.pets_rounded,
                      size: 40,
                      color: PetColors.dark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'PetCare',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: PetColors.dark,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),

              // Tagline
              const Text(
                'Trusted care for your pets, nearby.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: PetColors.dark,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),

              // Supporting text
              const Text(
                'Connect with verified dog walkers, sitters, and groomers in your neighborhood with real-time GPS tracking.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: PetColors.darkMuted,
                  height: 1.45,
                ),
              ),

              const Spacer(flex: 3),

              // Highlights
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PetColors.border),
                ),
                child: Column(
                  children: [
                    _buildTrustRow(
                      Icons.verified_rounded,
                      PetColors.sage,
                      'Verified Providers',
                      'Strict background check & experience vetting',
                    ),
                    const Divider(height: 24),
                    _buildTrustRow(
                      Icons.navigation_rounded,
                      PetColors.dark,
                      'Live GPS Tracking',
                      'Watch real-time walks with safe-zone security',
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Primary CTA
              PetCareButton(
                label: 'Get Started',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Secondary CTA
              PetCareButton(
                label: 'Already have an account? Sign in',
                type: PetButtonType.ghost,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustRow(IconData icon, Color iconColor, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: PetColors.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: PetColors.darkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
