import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late Timer _timer;
  late Timer _locationTimer;
  int _seconds = 0;

  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startLocationTracking();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _locationTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          setState(() {
            latitude = position.latitude;
            longitude = position.longitude;
          });
        });
  }

  void _stopEmergency() {
    _timer.cancel();
    _locationTimer.cancel();
    Navigator.pop(context);
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String get mapsLink {
    if (latitude == null || longitude == null) return 'Fetching location...';
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  @override
  void dispose() {
    _timer.cancel();
    _locationTimer.cancel();
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
          const Icon(Icons.warning_rounded, size: 100, color: Colors.red),
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
            'Live location sharing enabled',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),

          // ⏱ Timer
          Text(
            'Active for ${_formatTime(_seconds)}',
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 20),

          // 📍 Location Info
          Text(
            latitude == null
                ? 'Fetching location...'
                : 'Lat: $latitude\nLng: $longitude',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),
          Text(
            mapsLink,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.blue),
          ),

          const SizedBox(height: 40),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            onPressed: _stopEmergency,
            child: const Text('STOP EMERGENCY'),
          ),
        ],
      ),
    );
  }
}
