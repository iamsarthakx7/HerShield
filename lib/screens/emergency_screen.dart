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

  bool _sosEnded = false; // 🔒 PREVENT DOUBLE STOP

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
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  // 📍 Location + SOS + Alerts
  Future<void> _startLocationTracking() async {
    // 1️⃣ GPS service check
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showError('Please enable location services');
      return;
    }

    // 2️⃣ Permission
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

    // 3️⃣ Last known location (fast)
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      latitude = last.latitude;
      longitude = last.longitude;
    }

    // 4️⃣ Accurate location
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    latitude = pos.latitude;
    longitude = pos.longitude;

    // 🔥 CREATE SOS ONCE
    if (AppState.activeSosId == null) {
      AppState.activeSosId = await _sosService.startSOS(
        latitude: latitude!,
        longitude: longitude!,
      );
    }

    // 🚨 SEND ALERT ONCE
    if (!AppState.alertSent) {
      await _alertService.sendSOSAlert(
        latitude: latitude!,
        longitude: longitude!,
      );
      AppState.alertSent = true;
    }

    // 🔄 LIVE LOCATION UPDATES
    _locationTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
          final p = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          if (!mounted) return;

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

  // 🛑 STOP EMERGENCY (MANUAL)
  Future<void> _stopEmergency() async {
    if (_sosEnded) return;
    _sosEnded = true;

    final sosId = AppState.activeSosId;
    if (sosId != null) {
      await _sosService.stopSOS(sosId);
    }

    _cleanupAndExit();
  }

  // 🔥 FAILSAFE: AUTO STOP IF SCREEN DISPOSED
  @override
  void dispose() {
    if (!_sosEnded && AppState.activeSosId != null) {
      _sosService.stopSOS(AppState.activeSosId!);
    }

    _uiTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  // 🔄 RESET APP STATE
  void _cleanupAndExit() {
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

          const SizedBox(height: 25),

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
