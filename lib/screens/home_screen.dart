import 'package:flutter/material.dart';

import '../services/shake_service.dart';
import '../utils/app_state.dart';
import '../constants/app_colors.dart';

import 'emergency_screen.dart';
import 'settings_screen.dart';
import 'safety_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShakeService _shakeService = ShakeService();

  // 🚨 SOS TRIGGER
  void _triggerSOS() {
    if (AppState.emergencyActive) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EmergencyScreen()),
      );
      return;
    }

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

  // 🧠 OPEN GEMINI ASSISTANT
  void _openAssistant(SafetyChatMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SafetyChatScreen(mode: mode),
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
        children: [
          const SizedBox(height: 20),

          // 🧠 SAFETY ASSISTANT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get help before things escalate',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                _assistantButton(
                  text: 'I feel unsafe',
                  icon: Icons.warning_amber_rounded,
                  onTap: () =>
                      _openAssistant(SafetyChatMode.unsafe),
                ),
                _assistantButton(
                  text: 'I’m panicking',
                  icon: Icons.favorite_border,
                  onTap: () =>
                      _openAssistant(SafetyChatMode.panic),
                ),
                _assistantButton(
                  text: 'I’m confused',
                  icon: Icons.help_outline,
                  onTap: () =>
                      _openAssistant(SafetyChatMode.confused),
                ),
                _assistantButton(
                  text: 'Talk to assistant',
                  icon: Icons.chat_bubble_outline,
                  onTap: () =>
                      _openAssistant(SafetyChatMode.general),
                ),
              ],
            ),
          ),

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

          const SizedBox(height: 12),

          Text(
            'Use only if you are in immediate danger',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 30),

          // ⚙️ SETTINGS
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            child: Text(
              'Settings',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 🔘 Assistant Button
  Widget _assistantButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
