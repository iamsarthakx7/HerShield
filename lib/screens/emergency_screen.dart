import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/app_state.dart';
import '../services/sos_service.dart';
import '../services/alert_service.dart';
import '../services/nearby_help_service.dart';
import '../constants/app_colors.dart';

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

  bool _sosEnded = false; // prevent double stop

  @override
  void initState() {
    super.initState();

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

  void _startUiTimer() {
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  Future<void> _startLocationTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Please enable location services');
      return;
    }

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

    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      latitude = last.latitude;
      longitude = last.longitude;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    latitude = pos.latitude;
    longitude = pos.longitude;

    // Create SOS once
    if (AppState.activeSosId == null) {
      AppState.activeSosId = await _sosService.startSOS(
        latitude: latitude!,
        longitude: longitude!,
      );
    }

    // Send alert once
    if (!AppState.alertSent) {
      await _alertService.sendSOSAlert(
        latitude: latitude!,
        longitude: longitude!,
      );
      AppState.alertSent = true;
    }

    // Live location updates
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

  Future<void> _stopEmergency() async {
    if (_sosEnded) return;
    _sosEnded = true;

    final sosId = AppState.activeSosId;
    if (sosId != null) {
      await _sosService.stopSOS(sosId);
    }

    _cleanupAndExit();
  }

  @override
  void dispose() {
    if (!_sosEnded && AppState.activeSosId != null) {
      _sosService.stopSOS(AppState.activeSosId!);
    }

    _uiTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

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
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.emergency,
      ),
    );
  }

  String _format(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Mode'),
        backgroundColor: AppColors.emergency,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 60,
                    color: AppColors.emergency,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Emergency Active',
                  style:
                  Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.emergency,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Active for ${_format(_seconds)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                // Location card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          latitude == null
                              ? 'Fetching location...'
                              : 'Latitude: $latitude\nLongitude: $longitude',
                          textAlign: TextAlign.center,
                        ),
                        if (latitude != null && longitude != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'https://www.google.com/maps?q=$latitude,$longitude',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Quick actions
                if (latitude != null && longitude != null)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.local_police),
                          label: const Text('Police'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: () {
                            NearbyHelpService.openPolice(
                              latitude!,
                              longitude!,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.local_hospital),
                          label: const Text('Hospital'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: () {
                            NearbyHelpService.openHospital(
                              latitude!,
                              longitude!,
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 36),

                // Stop button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emergency,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  onPressed: _stopEmergency,
                  child: const Text(
                    'STOP EMERGENCY',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
