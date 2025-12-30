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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ShakeService _shakeService = ShakeService();
  late AnimationController _sosPulseController;
  late Animation<double> _sosPulseAnimation;

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

    // Subtle SOS pulse animation
    _sosPulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _sosPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _sosPulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _shakeService.stopListening();
    _sosPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // 🧭 APP BAR WITH SUBTLE ELEVATION
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Her',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Shield',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: const Color(0xFF475569),
                size: 22,
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
          ),
        ],
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // 🧠 SAFETY ASSISTANT HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFF6366F1),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Safety Assistant',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Text(
                          'Get immediate help and guidance',
                          style: TextStyle(
                            color: const Color(0xFF64748B),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Assistant Buttons Grid - COMPACT VERSION
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _compactAssistantCard(
                              title: 'Feeling Unsafe',
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFEF4444),
                              onTap: () => _openAssistant(SafetyChatMode.unsafe),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _compactAssistantCard(
                              title: 'Panic Mode',
                              icon: Icons.favorite_border,
                              color: const Color(0xFFEC4899),
                              onTap: () => _openAssistant(SafetyChatMode.panic),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _compactAssistantCard(
                              title: 'Need Clarity',
                              icon: Icons.help_outline,
                              color: const Color(0xFF8B5CF6),
                              onTap: () => _openAssistant(SafetyChatMode.confused),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _compactAssistantCard(
                              title: 'Talk Freely',
                              icon: Icons.chat_bubble_outline,
                              color: const Color(0xFF6366F1),
                              onTap: () => _openAssistant(SafetyChatMode.general),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 🚨 SOS SECTION - ALWAYS VISIBLE
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isSmallScreen ? 8 : 24),

                      // SOS Button
                      Container(
                        height: isSmallScreen ? 200 : 240,
                        width: isSmallScreen ? 200 : 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: AppState.emergencyActive
                                ? [
                              const Color(0xFFCBD5E1).withOpacity(0.3),
                              const Color(0xFFCBD5E1).withOpacity(0.1),
                              Colors.transparent,
                            ]
                                : [
                              const Color(0xFFEF4444).withOpacity(0.2),
                              const Color(0xFFEF4444).withOpacity(0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.1, 0.5, 1.0],
                          ),
                        ),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _sosPulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: AppState.emergencyActive
                                    ? 1.0
                                    : _sosPulseAnimation.value,
                                child: GestureDetector(
                                  onTap: AppState.emergencyActive
                                      ? null
                                      : _triggerSOS,
                                  child: Container(
                                    height: isSmallScreen ? 140 : 170,
                                    width: isSmallScreen ? 140 : 170,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppState.emergencyActive
                                          ? const LinearGradient(
                                        colors: [
                                          Color(0xFFCBD5E1),
                                          Color(0xFF94A3B8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                          : LinearGradient(
                                        colors: [
                                          const Color(0xFFEF4444),
                                          const Color(0xFFDC2626),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: AppState.emergencyActive
                                          ? [
                                        BoxShadow(
                                          color: const Color(0xFF64748B)
                                              .withOpacity(0.2),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                          : [
                                        BoxShadow(
                                          color: const Color(0xFFEF4444)
                                              .withOpacity(0.4),
                                          blurRadius: 20,
                                          spreadRadius: 6,
                                          offset: const Offset(0, 6),
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFFDC2626)
                                              .withOpacity(0.2),
                                          blurRadius: 12,
                                          spreadRadius: 3,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Inner glow effect
                                        if (!AppState.emergencyActive)
                                          Container(
                                            height: isSmallScreen ? 120 : 150,
                                            width: isSmallScreen ? 120 : 150,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: RadialGradient(
                                                colors: [
                                                  Colors.white.withOpacity(0.3),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.warning_rounded,
                                              color: Colors.white,
                                              size: isSmallScreen ? 36 : 42,
                                              shadows: [
                                                const Shadow(
                                                  color: Colors.black26,
                                                  blurRadius: 6,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'SOS',
                                              style: TextStyle(
                                                fontSize:
                                                isSmallScreen ? 40 : 46,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: 2,
                                                shadows: [
                                                  const Shadow(
                                                    color: Colors.black38,
                                                    blurRadius: 8,
                                                    offset: Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // WARNING MESSAGE - ALWAYS VISIBLE
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppState.emergencyActive
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E293B).withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                AppState.emergencyActive
                                    ? Icons.error_outline_rounded
                                    : Icons.info_outline_rounded,
                                color: AppState.emergencyActive
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF6366F1),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppState.emergencyActive
                                      ? 'Emergency Active • Help is on the way'
                                      : 'For immediate danger only • Shake to activate',
                                  style: TextStyle(
                                    color: AppState.emergencyActive
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF475569),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 🔘 Compact Assistant Card (OPTIMIZED FOR ONE SCREEN)
  Widget _compactAssistantCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}