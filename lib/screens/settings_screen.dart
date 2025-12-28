import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    debugPrint('🔥 LOGOUT BUTTON PRESSED');

    try {
      await FirebaseAuth.instance.signOut();
      debugPrint('✅ FIREBASE SIGNOUT DONE');

      // 🔥 Clear navigation stack
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('❌ SIGNOUT ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 GENERAL SECTION
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.person, color: AppColors.primary),
                  title: Text('Profile'),
                ),
                Divider(height: 1),
                ListTile(
                  leading:
                  Icon(Icons.notifications, color: AppColors.primary),
                  title: Text('Notifications'),
                ),
                Divider(height: 1),
                ListTile(
                  leading:
                  Icon(Icons.location_on, color: AppColors.primary),
                  title: Text('Location Access'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 🔓 LOGOUT SECTION
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading:
              const Icon(Icons.logout, color: AppColors.emergency),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.emergency,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}
