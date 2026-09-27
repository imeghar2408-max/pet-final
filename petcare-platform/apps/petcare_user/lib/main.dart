import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_messenger.dart';
import 'core/theme.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }
  runApp(const PetCareUserApp());
}

class PetCareUserApp extends StatelessWidget {
  const PetCareUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCare · Pet Owner',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: PetTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
