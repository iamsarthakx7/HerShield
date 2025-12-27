import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            subtitle: Text('View or edit profile details'),
          ),
          const Divider(),

          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            subtitle: Text('Manage alert preferences'),
          ),
          const Divider(),

          const ListTile(
            leading: Icon(Icons.location_on),
            title: Text('Location Access'),
            subtitle: Text('Manage location permissions'),
          ),
          const Divider(),

          // 🔓 LOGOUT
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              // 🔑 RESET APP STATE
              AppState.isLoggedIn = false;
              AppState.hasContacts = false;

              // 🚪 GO TO LOGIN & CLEAR STACK
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
