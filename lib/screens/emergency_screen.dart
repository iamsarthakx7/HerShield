import 'dart:async';
import 'package:flutter/material.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late Timer _timer;
  int _seconds = 0;
  bool emergencyActive = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _stopEmergency() {
    _timer.cancel();
    setState(() {
      emergencyActive = false;
    });

    Navigator.pop(context);
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('Emergency Mode'),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_rounded,
            size: 100,
            color: Colors.red,
          ),
          const SizedBox(height: 20),

          const Text(
            'Emergency Active',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Alerts sent to trusted contacts\nLive location sharing enabled',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 20),

          // ⏱ Timer
          Text(
            'Active for ${_formatTime(_seconds)}',
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 30),

          // 📞 Emergency Actions (UI only)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: () {
                  // Call police later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling Police (112)...')),
                  );
                },
                icon: const Icon(Icons.local_police),
                label: const Text('Police'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: () {
                  // Call contact later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling emergency contact...')),
                  );
                },
                icon: const Icon(Icons.call),
                label: const Text('Contact'),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // 🛑 Stop Emergency
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            onPressed: _stopEmergency,
            child: const Text(
              'STOP EMERGENCY',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
