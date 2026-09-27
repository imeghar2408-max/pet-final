import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'features/auth/phone_login_screen.dart';
import 'features/home/provider_home_screen.dart';
import 'core/app_messenger.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PetCareProviderApp());
}

class PetCareProviderApp extends StatelessWidget {
  const PetCareProviderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCare Provider',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: ProviderTheme.themeData(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: ProviderTheme.background,
              body: Center(child: CircularProgressIndicator(color: ProviderTheme.sagePrimary)),
            );
          }
          if (snapshot.hasData) return const ProviderHomeScreen();
          return const PhoneLoginScreen();
        },
      ),
    );
  }
}
