import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const HerShieldApp());
}

class HerShieldApp extends StatelessWidget {
  const HerShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HerShield',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),

      // 🔥 SINGLE SOURCE OF AUTH NAVIGATION
      home: AuthGate(),
    );
  }
}

/// ✅ AuthGate decides which screen to show
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint('🔁 AUTH STATE: ${snapshot.data}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔓 Logged out
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 🔐 Logged in
        return const HomeScreen();
      },
    );
  }
}
