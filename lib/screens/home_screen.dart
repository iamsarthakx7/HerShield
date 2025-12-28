import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // 🔍 Background contact sync (NON-BLOCKING)
  Future<void> _syncContactsSilently() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('contacts')
          .limit(1)
          .get();

      AppState.hasContacts = snapshot.docs.isNotEmpty;
      AppState.contactsChecked = true;
    } catch (_) {
      // Fail silently — never block SOS
    }
  }

  // 🚨 INSTANT SOS (OPTIMISTIC TRIGGER)
  void _triggerSOS() {
    if (AppState.emergencyActive) return;

    // 🚀 START SOS IMMEDIATELY (NO DELAY)
    AppState.emergencyActive = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyScreen(),
      ),
    );

    // ⚠️ Background validation (NON-BLOCKING)
    if (AppState.contactsChecked && !AppState.hasContacts) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ No emergency contacts found. Please add contacts.',
            ),
          ),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // 🎯 Start shake detection
    _shakeService.startListening(_triggerSOS);

    // 🔍 Sync contacts silently in background
    _syncContactsSilently();
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
          // 🔴 SOS BUTTON (ALWAYS AVAILABLE)
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

          // 👥 Manage Contacts
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactsScreen(),
                ),
              );

              // 🔄 Re-sync after returning
              _syncContactsSilently();
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
