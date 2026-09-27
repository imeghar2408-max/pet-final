import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';
import 'welcome_screen.dart';
import 'owner_profile_setup_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const WelcomeScreen();
        }

        // Authenticated in Firebase: verify backend profile registration
        return FutureBuilder<Map<String, dynamic>?>(
          future: UserApiService().getMe(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashScreen();
            }

            final profile = profileSnapshot.data;
            if (profile != null && profile['petOwnerProfile'] != null) {
              return const HomeScreen();
            }

            // User is authenticated in Firebase but hasn't created owner profile in Postgres
            return OwnerProfileSetupScreen(
              phone: user.phoneNumber ?? '',
            );
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: PetColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets_rounded,
                size: 44,
                color: PetColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'PetCare',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: PetColors.dark,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(PetColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
