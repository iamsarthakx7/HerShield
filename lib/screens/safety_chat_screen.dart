import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/gemini_service.dart';
import 'emergency_screen.dart';

enum SafetyChatMode {
  unsafe,
  panic,
  confused,
  general,
}

class SafetyChatScreen extends StatefulWidget {
  final SafetyChatMode mode;

  const SafetyChatScreen({super.key, required this.mode});

  @override
  State<SafetyChatScreen> createState() => _SafetyChatScreenState();
}

class _SafetyChatScreenState extends State<SafetyChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  final GeminiService _geminiService = GeminiService();

  bool _loading = false;
  bool _showEscalation = false;
  String _emergencyAdvice = '';

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text: _initialMessageForMode(widget.mode),
        isUser: false,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  String _initialMessageForMode(SafetyChatMode mode) {
    switch (mode) {
      case SafetyChatMode.unsafe:
        return 'I\'m here with you. You\'re safe right now. Tell me what\'s making you feel unsafe.';
      case SafetyChatMode.panic:
        return 'Let\'s slow things down together. Take a deep breath. I\'m listening.';
      case SafetyChatMode.confused:
        return 'It\'s okay to feel confused. Tell me what\'s going on.';
      case SafetyChatMode.general:
      default:
        return 'Hi, I\'m your safety assistant. How can I help you?';
    }
  }

  String _systemPromptForMode(SafetyChatMode mode) {
    switch (mode) {
      case SafetyChatMode.panic:
        return 'You are a calm assistant helping someone panicking. Keep responses short and grounding.';
      case SafetyChatMode.unsafe:
        return 'You are a safety assistant giving practical advice without alarming.';
      case SafetyChatMode.confused:
        return 'You are a gentle guide helping someone think clearly.';
      case SafetyChatMode.general:
      default:
        return 'You are a helpful safety assistant.';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ============================
  // 🚨 OFFLINE EMERGENCY FALLBACK
  // ============================
  bool _fallbackDetectDanger(String text) {
    final keywords = [
      'help',
      'scared',
      'following',
      'chasing',
      'attack',
      'threat',
      'danger',
      'panic',
      'unsafe',
      'alone',
      'someone behind',
    ];

    final lower = text.toLowerCase();
    return keywords.any((k) => lower.contains(k));
  }

  // ============================
  // 📞 CALL EMERGENCY HELPER
  // ============================
  Future<void> _callEmergency(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  // ============================
  // 🚨 UPDATED SEND MESSAGE LOGIC
  // ============================
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _loading = true;
      _showEscalation = false;
      _emergencyAdvice = '';
    });

    _controller.clear();
    _scrollToBottom();

    try {
      // 1️⃣ AI SAFETY ANALYSIS
      final analysis =
      await _geminiService.analyzeSafetyMessage(text);

      final String riskLevel = analysis['risk_level'] ?? 'low';
      final bool recommendSos = analysis['recommend_sos'] ?? false;
      final String advice = analysis['advice'] ?? '';

      // 2️⃣ NORMAL ASSISTANT RESPONSE
      final reply = await _geminiService.sendMessage(
        systemPrompt: _systemPromptForMode(widget.mode),
        userMessage: text,
      );

      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));

        if (riskLevel == 'high' && recommendSos) {
          _showEscalation = true;
          _emergencyAdvice = advice;
        }
      });
    } catch (_) {
      // 🔥 FALLBACK IF GEMINI FAILS
      final bool fallbackDanger = _fallbackDetectDanger(text);

      setState(() {
        _messages.add(
          _ChatMessage(
            text:
            'I\'m here with you. If you feel unsafe, help is available.',
            isUser: false,
          ),
        );

        if (fallbackDanger) {
          _showEscalation = true;
          _emergencyAdvice =
          'If you are in immediate danger, call emergency number 112.';
        }
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _titleForMode(widget.mode),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.help_outline_rounded,
                size: 22,
              ),
              color: const Color(0xFF475569),
              onPressed: () {
                // Optional: Add help dialog
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Safety Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.08),
                  const Color(0xFF8B5CF6).withOpacity(0.04),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconForMode(widget.mode),
                    color: const Color(0xFF6366F1),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _subtitleForMode(widget.mode),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'You\'re not alone. HerShield is here to help.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8FAFC),
                    Color(0xFFF1F5F9),
                  ],
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _ChatBubble(message: _messages[index]);
                },
              ),
            ),
          ),

          // Loading Indicator
          if (_loading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'HerShield is responding...',
                    style: TextStyle(
                      color: const Color(0xFF475569),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // 🚨 EMERGENCY ESCALATION CARD
          if (_showEscalation)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFFECACA),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Safety Alert',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_emergencyAdvice.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _emergencyAdvice,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF991B1B),
                          height: 1.4,
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmergencyScreen(),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_rounded, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'START SOS',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _callEmergency('112'),
                        child: Text(
                          'CALL 112',
                          style: TextStyle(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFF6366F1)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _callEmergency('181'),
                        child: Text(
                          'WOMEN HELPLINE',
                          style: TextStyle(
                            color: const Color(0xFF6366F1),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _showEscalation = false);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                        ),
                        child: Text(
                          'I\'M OK',
                          style: TextStyle(
                            color: const Color(0xFF16A34A),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Message Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      enabled: !_loading,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type your message here...',
                        hintStyle: TextStyle(
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w400,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: const Color(0xFF6366F1),
                            size: 22,
                          ),
                          onPressed: _loading ? null : _sendMessage,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleForMode(SafetyChatMode mode) {
    switch (mode) {
      case SafetyChatMode.panic:
        return 'Calm Support';
      case SafetyChatMode.unsafe:
        return 'Safety Support';
      case SafetyChatMode.confused:
        return 'Guidance';
      case SafetyChatMode.general:
      default:
        return 'Safety Assistant';
    }
  }

  String _subtitleForMode(SafetyChatMode mode) {
    switch (mode) {
      case SafetyChatMode.panic:
        return 'Breathing support & calming guidance';
      case SafetyChatMode.unsafe:
        return 'Practical safety advice & support';
      case SafetyChatMode.confused:
        return 'Clear thinking & decision support';
      case SafetyChatMode.general:
      default:
        return 'Your personal safety assistant';
    }
  }

  IconData _iconForMode(SafetyChatMode mode) {
    switch (mode) {
      case SafetyChatMode.panic:
        return Icons.favorite_border_rounded;
      case SafetyChatMode.unsafe:
        return Icons.warning_amber_rounded;
      case SafetyChatMode.confused:
        return Icons.help_outline_rounded;
      case SafetyChatMode.general:
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
      message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!message.isUser)
              Container(
                margin: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      'HerShield',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF6366F1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: message.isUser
                        ? Colors.white
                        : const Color(0xFF1E293B),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            if (message.isUser)
              Container(
                margin: const EdgeInsets.only(right: 8, top: 4),
                child: Text(
                  'You',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}