import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import 'emergency_screen.dart';
import '../constants/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text: _initialMessageForMode(widget.mode),
        isUser: false,
      ),
    );
  }

  String _initialMessageForMode(SafetyChatMode mode) {
    switch (mode) {
      case SafetyChatMode.unsafe:
        return 'I’m here with you. You’re safe right now. Tell me what’s making you feel unsafe.';
      case SafetyChatMode.panic:
        return 'Let’s slow things down together. Take a deep breath. I’m listening.';
      case SafetyChatMode.confused:
        return 'It’s okay to feel confused. Tell me what’s going on.';
      case SafetyChatMode.general:
      default:
        return 'Hi, I’m your safety assistant. How can I help you?';
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

  bool _isDangerousMessage(String text) {
    final dangerKeywords = [
      'help',
      'following me',
      'chasing',
      'threat',
      'attack',
      'alone',
      'scared',
      'someone behind',
      'unsafe',
      'panic',
    ];

    final lower = text.toLowerCase();
    return dangerKeywords.any((k) => lower.contains(k));
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _loading = true;
      _showEscalation = _isDangerousMessage(text);
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await _geminiService.sendMessage(
        systemPrompt: _systemPromptForMode(widget.mode),
        userMessage: text,
      );

      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
    } catch (_) {
      setState(() {
        _messages.add(
          _ChatMessage(
            text:
            'I’m here with you. Something went wrong. Please check your connection and try again.',
            isUser: false,
          ),
        );
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_titleForMode(widget.mode)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'You’re not alone. HerShield is here to help.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'HerShield is responding…',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

          if (_showEscalation)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.emergency.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.emergency),
              ),
              child: Column(
                children: [
                  const Text(
                    'This sounds serious.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.emergency,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Do you want to start SOS so your contacts can help?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emergency,
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmergencyScreen(),
                            ),
                          );
                        },
                        child: const Text('START SOS'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _showEscalation = false);
                        },
                        child: const Text(
                          'I’m OK',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_loading,
                    decoration: InputDecoration(
                      hintText: 'Type your message…',
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _loading ? null : _sendMessage,
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
        return 'Guided Help';
      case SafetyChatMode.general:
      default:
        return 'Safety Assistant';
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
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 2),
              child: Text(
                'HerShield',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: message.isUser
                  ? AppColors.primary
                  : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isUser
                    ? AppColors.white
                    : AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}
