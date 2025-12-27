import 'package:flutter/material.dart';
import '../services/shake_service.dart';
import 'emergency_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShakeService _shakeService = ShakeService();

  void _triggerSOS() {
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
      body: Center(
        child: GestureDetector(
          onTap: _triggerSOS,
          child: Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.red,
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
      ),
    );
  }
}
