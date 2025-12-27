import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    debugPrint('🔥 LOGOUT BUTTON PRESSED');

    try {
      await FirebaseAuth.instance.signOut();
      debugPrint('✅ FIREBASE SIGNOUT DONE');

      // 🔥 THIS IS THE FIX: CLEAR STACK
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
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.red,
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
          ),
          const Divider(),

          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
          ),
          const Divider(),

          const ListTile(
            leading: Icon(Icons.location_on),
            title: Text('Location Access'),
          ),
          const Divider(),

          // 🔓 LOGOUT
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
