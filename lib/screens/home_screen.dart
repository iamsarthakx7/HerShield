import 'package:flutter/material.dart';
import '../services/shake_service.dart';
import '../utils/app_state.dart';
import 'emergency_screen.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShakeService _shakeService = ShakeService();

  // 🚨 SOS trigger with safety checks
  void _triggerSOS() {
    if (AppState.emergencyActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency already active')),
      );
      return;
    }

    if (!AppState.hasContacts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one emergency contact first'),
        ),
      );
      return;
    }

    AppState.emergencyActive = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _shakeService.startListening(_triggerSOS);
  }

  @override
  void dispose() {
    _shakeService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HerShield'),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🔴 SOS Button
          GestureDetector(
            onTap: AppState.emergencyActive ? null : _triggerSOS,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: AppState.emergencyActive ? Colors.grey : Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // 👥 Manage Emergency Contacts
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactsScreen(),
                ),
              );
            },
            child: const Text(
              'Manage Emergency Contacts',
              style: TextStyle(fontSize: 16),
            ),
          ),

          const SizedBox(height: 10),

          // ⚙️ Settings
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            child: const Text(
              'Settings',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
