import 'package:flutter/material.dart';
import '../services/shake_service.dart';
import '../utils/app_state.dart';
import 'emergency_screen.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';
import '../constants/app_colors.dart';


class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShakeService _shakeService = ShakeService();

  void _triggerSOS() {
    // 🔁 Resume if already active
    if (AppState.emergencyActive) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EmergencyScreen()),
      );
      return;
    }

    // ✅ Start emergency instantly
    AppState.emergencyActive = true;

    if (AppState.emergencyStartTime == 0) {
      AppState.emergencyStartTime =
          DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyScreen()),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'HerShield',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // 🚨 SOS BUTTON
          GestureDetector(
            onTap: AppState.emergencyActive ? null : _triggerSOS,
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: AppState.emergencyActive
                      ? [Colors.grey, Colors.grey.shade600]
                      : [
                    AppColors.primary,
                    AppColors.emergency,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.45),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          Text(
            'Tap in emergency',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),

          const Spacer(),

          // 👥 MANAGE CONTACTS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactsScreen(),
                  ),
                );
                _syncContactsSilently();
              },
              child: const Text(
                'Manage Emergency Contacts',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ⚙️ SETTINGS
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            child: Text(
              'Settings',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _syncContactsSilently() {}


}
