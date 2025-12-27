import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/app_state.dart';

void main() {
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

      // 🔑 ENTRY POINT LOGIC
      home: AppState.isLoggedIn
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
