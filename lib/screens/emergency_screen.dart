import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/app_state.dart';
import '../services/sos_service.dart';
import '../services/alert_service.dart';
import '../services/nearby_help_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  Timer? _uiTimer;
  Timer? _locationTimer;

  int _seconds = 0;
  double? latitude;
  double? longitude;

  final SosService _sosService = SosService();
  final AlertService _alertService = AlertService();

  @override
  void initState() {
    super.initState();

    // ⏱ Resume timer if emergency already active
    if (AppState.emergencyStartTime > 0) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _seconds = now - AppState.emergencyStartTime;
    } else {
      AppState.emergencyStartTime =
          DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }

    _startUiTimer();
    _startLocationTracking();
  }

  // ⏱ UI timer
  void _startUiTimer() {
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  // 📍 Location + SOS + Alerts
  Future<void> _startLocationTracking() async {
    // 1️⃣ Check GPS service
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Please enable location services');
      return;
    }

    // 2️⃣ Permission handling
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      _showError(
        'Location permission permanently denied.\nEnable it from Settings.',
      );
      return;
    }

    // 3️⃣ Fast last-known location
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      setState(() {
        latitude = last.latitude;
        longitude = last.longitude;
      });
    }

    // 4️⃣ Accurate GPS
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      latitude = pos.latitude;
      longitude = pos.longitude;
    });

    // 🔥 Create SOS ONCE
    if (AppState.activeSosId == null) {
      AppState.activeSosId = await _sosService.startSOS(
        latitude: latitude!,
        longitude: longitude!,
      );
    }

    // 🚨 Send alerts ONCE
    if (!AppState.alertSent) {
      await _alertService.sendSOSAlert(
        latitude: latitude!,
        longitude: longitude!,
      );
      AppState.alertSent = true;
    }

    // 🔄 Location updates
    _locationTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
          final p = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          setState(() {
            latitude = p.latitude;
            longitude = p.longitude;
          });

          if (AppState.activeSosId != null) {
            await _sosService.updateLocation(
              sosId: AppState.activeSosId!,
              latitude: p.latitude,
              longitude: p.longitude,
            );
          }
        });
  }

  // 🛑 Stop emergency
  Future<void> _stopEmergency() async {
    AppState.emergencyActive = false;
    AppState.alertSent = false;
    AppState.activeSosId = null;
    AppState.emergencyStartTime = 0;

    _uiTimer?.cancel();
    _locationTimer?.cancel();

    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _format(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _uiTimer?.cancel();
    _locationTimer?.cancel();
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
          const SizedBox(height: 10),

          Text(
            'Active for ${_format(_seconds)}',
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 20),

          Text(
            latitude == null
                ? 'Fetching location...'
                : 'Lat: $latitude\nLng: $longitude',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          if (latitude != null && longitude != null)
            Text(
              'https://www.google.com/maps?q=$latitude,$longitude',
              style: const TextStyle(color: Colors.blue),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 25),

          // 🚓 Police & 🏥 Hospital
          if (latitude != null && longitude != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.local_police),
                  label: const Text('Police'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    NearbyHelpService.openPolice(latitude!, longitude!);
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.local_hospital),
                  label: const Text('Hospital'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    NearbyHelpService.openHospital(latitude!, longitude!);
                  },
                ),
              ],
            ),

          const SizedBox(height: 35),

          // 🛑 STOP
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
