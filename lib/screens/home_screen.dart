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

      // 🧭 APP BAR (CLEAN & MODERN)
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'HerShield',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 20),

          // 🧠 SAFETY ASSISTANT SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Assistant',
                  style: TextStyle(
                    fontSize: 20,
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
                const SizedBox(height: 18),

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

          // 🚨 SOS BUTTON (HERO ACTION)
          GestureDetector(
            onTap: AppState.emergencyActive ? null : _triggerSOS,
            child: Container(
              height: 230,
              width: 230,
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
                    color: AppColors.emergency.withOpacity(0.45),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
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
        ],
      ),
    );
  }

  // 🔘 Assistant Button (POLISHED)
  Widget _assistantButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 14),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
