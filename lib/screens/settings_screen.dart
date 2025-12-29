import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

import 'profile_screen.dart';
import 'contacts_screen.dart';
import 'sos_history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationAllowed = false;
  bool _notificationAllowed = false;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
  }

  /// 🔍 Load permission status
  Future<void> _loadPermissionStatus() async {
    final location = await Permission.location.status;
    final notification = await Permission.notification.status;

    setState(() {
      _locationAllowed = location.isGranted;
      _notificationAllowed = notification.isGranted;
    });
  }

  /// ⚙️ Open system app settings
  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  /// 🔓 Logout
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPermissionStatus,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            // 👤 ACCOUNT
            _sectionTitle('Account'),

            _settingsTile(
              icon: Icons.person,
              title: 'Profile',
              subtitle: 'View & edit your personal details',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),

            _settingsTile(
              icon: Icons.history,
              title: 'SOS History',
              subtitle: 'View past emergency alerts',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SOSHistoryScreen(),
                  ),
                );
              },
            ),

            // 🚨 EMERGENCY
            _sectionTitle('Emergency'),

            _settingsTile(
              icon: Icons.contacts,
              title: 'Emergency Contacts',
              subtitle: 'Manage trusted contacts (up to 5)',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ContactsScreen(),
                  ),
                );
              },
            ),

            _permissionTile(
              icon: Icons.location_on,
              title: 'Location Access',
              allowed: _locationAllowed,
              onTap: _openAppSettings,
            ),

            // ⚙️ APP
            _sectionTitle('App'),

            _permissionTile(
              icon: Icons.notifications,
              title: 'Notifications',
              allowed: _notificationAllowed,
              onTap: _openAppSettings,
            ),

            const SizedBox(height: 20),

            // 🔓 LOGOUT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _logout(context),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 🧱 SECTION TITLE
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // 🧩 NORMAL TILE
  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _baseTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // 🔐 PERMISSION TILE
  Widget _permissionTile({
    required IconData icon,
    required String title,
    required bool allowed,
    required VoidCallback onTap,
  }) {
    return _baseTile(
      icon: icon,
      title: title,
      subtitle: allowed ? 'Allowed' : 'Denied',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: allowed ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          allowed ? 'Allowed' : 'Denied',
          style: TextStyle(
            color: allowed ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  // 🔧 BASE TILE
  Widget _baseTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.red),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }
}
