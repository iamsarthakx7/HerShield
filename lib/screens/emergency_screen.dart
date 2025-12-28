import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/app_state.dart';
import '../services/sos_service.dart';
import '../services/alert_service.dart';
import '../services/nearby_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  // ⏱ Timers
  late Timer _timer;
  late Timer _locationTimer;

  int _seconds = 0;

  // 📍 Location
  double? latitude;
  double? longitude;

  // 🔥 Services
  final SosService _sosService = SosService();
  final AlertService _alertService = AlertService();

  String? sosId;
  bool alertSent = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startLocationTracking();
  }

  // ⏱ Emergency timer
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  // 📍 Location tracking + Firestore + Alerts
  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 🔹 Initial location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    latitude = position.latitude;
    longitude = position.longitude;

    // 🔥 Create SOS event
    sosId = await _sosService.startSOS(
      latitude: latitude!,
      longitude: longitude!,
    );

    // 🚨 Send alerts ONCE
    if (!alertSent) {
      await _alertService.sendSOSAlert(
        latitude: latitude!,
        longitude: longitude!,
      );
      alertSent = true;
    }

    // 🔄 Update location every 5 seconds
    _locationTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
          Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          setState(() {
            latitude = pos.latitude;
            longitude = pos.longitude;
          });

          if (sosId != null) {
            await _sosService.updateLocation(
              sosId: sosId!,
              latitude: pos.latitude,
              longitude: pos.longitude,
            );
          }
        });
  }

  // 🛑 Stop Emergency
  Future<void> _stopEmergency() async {
    AppState.emergencyActive = false;

    _timer.cancel();
    _locationTimer.cancel();

    if (sosId != null) {
      await _sosService.stopSOS(sosId!);
    }

    Navigator.pop(context);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get mapsLink {
    if (latitude == null || longitude == null) {
      return 'Fetching location...';
    }
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
            'Live location & alerts enabled',
            style: TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 20),

          // ⏱ Timer
          Text(
            'Active for ${_formatTime(_seconds)}',
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 20),

          // 📍 Location
          Text(
            latitude == null
                ? 'Fetching location...'
                : 'Lat: $latitude\nLng: $longitude',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // 🌍 Maps link
          Text(
            mapsLink,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.blue),
          ),

          const SizedBox(height: 30),

          // 🚓 Nearby Help Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: latitude == null
                    ? null
                    : () {
                  NearbyService.openPolice(
                    latitude: latitude!,
                    longitude: longitude!,
                  );
                },
                icon: const Icon(Icons.local_police),
                label: const Text('Police'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: latitude == null
                    ? null
                    : () {
                  NearbyService.openHospital(
                    latitude: latitude!,
                    longitude: longitude!,
                  );
                },
                icon: const Icon(Icons.local_hospital),
                label: const Text('Hospital'),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // 🛑 Stop Emergency
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
