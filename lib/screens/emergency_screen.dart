import 'package:flutter/material.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Emergency Mode'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_rounded,
            color: Colors.red,
            size: 100,
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
            'Your location is being shared\nwith trusted contacts',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'STOP EMERGENCY',
              style: TextStyle(fontSize: 16),
            ),
          )
        ],
      ),
    );
  }
}
