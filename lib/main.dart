import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/sos_service.dart'; // ✅ ADD THIS

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
      theme: ThemeData(primarySwatch: Colors.red),
      home: const AuthGate(),
    );
  }
}

/// 🔐 SINGLE SOURCE OF TRUTH
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // ⏳ Waiting for auth
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final user = authSnapshot.data!;

        // 🔍 Check profile completeness
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (!profileSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data =
            profileSnapshot.data!.data() as Map<String, dynamic>?;

            final profileComplete =
                data != null && data['profileCompleted'] == true;

            // ❗ Force profile completion
            if (!profileComplete) {
              return const ProfileSetupScreen();
            }

            // ✅ AUTO CLOSE ANY ACTIVE SOS (🔥 FIX)
            Future.microtask(() {
              SosService().closeAnyActiveSOS();
            });

            // ✅ Logged in + clean SOS state
            return HomeScreen();
          },
        );
      },
    );
  }
}
