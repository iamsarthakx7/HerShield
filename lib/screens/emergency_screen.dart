import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  int _seconds = 0;

  double? latitude;
  double? longitude;

  // 🧠 Cached location (runtime fallback)
  double? _cachedLat;
  double? _cachedLng;

  bool _isOffline = false;
  bool _sosEnded = false;

  // 🕵️ Stealth calculator
  bool _isHidden = false;
  String _display = '0';
  double _first = 0;
  String _operator = '';

  final SosService _sosService = SosService();
  final AlertService _alertService = AlertService();

  // ============================================================
  // 🔁 INIT
  // ============================================================
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

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });

    _listenConnectivity();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _locationTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ============================================================
  // 🌐 CONNECTIVITY
  // ============================================================
  void _listenConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectivity(results);

    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_updateConnectivity);
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);

    if (mounted) setState(() => _isOffline = offline);
  }

  // ============================================================
  // 📍 LOCATION + SOS (WITH CACHE)
  // ============================================================
  Future<void> _startLocationTracking() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _useCachedLocation();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      _useCachedLocation();
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateLocation(pos.latitude, pos.longitude);
    } catch (_) {
      _useCachedLocation();
    }

    _locationTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
          try {
            final p = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );

            _updateLocation(p.latitude, p.longitude);

            if (AppState.activeSosId != null) {
              await _sosService.updateLocation(
                sosId: AppState.activeSosId!,
                latitude: p.latitude,
                longitude: p.longitude,
              );
            }
          } catch (_) {
            _useCachedLocation();
          }
        });
  }

  void _updateLocation(double lat, double lng) async {
    latitude = lat;
    longitude = lng;

    _cachedLat = lat;
    _cachedLng = lng;

    if (AppState.activeSosId == null) {
      AppState.activeSosId =
      await _sosService.startSOS(latitude: lat, longitude: lng);
    }

    if (!AppState.alertSent) {
      await _alertService.sendSOSAlert(latitude: lat, longitude: lng);
      AppState.alertSent = true;
    }

    if (mounted) setState(() {});
  }

  void _useCachedLocation() {
    if (_cachedLat != null && _cachedLng != null) {
      latitude = _cachedLat;
      longitude = _cachedLng;
      if (mounted) setState(() {});
    }
  }

  // ============================================================
  // 📞 CALL
  // ============================================================
  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ============================================================
  // 🛑 STOP SOS
  // ============================================================
  Future<void> _stopEmergency() async {
    if (_sosEnded) return;
    _sosEnded = true;

    if (AppState.activeSosId != null) {
      await _sosService.stopSOS(AppState.activeSosId!);
    }

    AppState.resetEmergency();
    Navigator.pop(context);
  }

  // ============================================================
  // 🧮 CALCULATOR LOGIC
  // ============================================================
  void _onKeyTap(String key) {
    setState(() {
      if (key == '⌫') {
        _display =
        _display.length > 1 ? _display.substring(0, _display.length - 1) : '0';
      } else if (key == 'AC') {
        _display = '0';
        _first = 0;
        _operator = '';
      } else if (['+', '-', '×', '÷'].contains(key)) {
        _first = double.parse(_display);
        _operator = key;
        _display = '0';
      } else if (key == '=') {
        final second = double.parse(_display);
        double result = 0;

        switch (_operator) {
          case '+':
            result = _first + second;
            break;
          case '-':
            result = _first - second;
            break;
          case '×':
            result = _first * second;
            break;
          case '÷':
            result = second == 0 ? 0 : _first / second;
            break;
        }

        _display = result.toString();
        _operator = '';
      } else {
        _display = _display == '0' ? key : _display + key;
      }
    });
  }

  // ============================================================
  // 🧱 BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return _isHidden ? _buildCalculator() : _buildEmergencyUI();
  }

  // ============================================================
  // 🚨 EMERGENCY UI
  // ============================================================
  Widget _buildEmergencyUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Mode'),
        backgroundColor: Colors.red,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_off),
            onPressed: () => setState(() => _isHidden = true),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.warning_rounded, size: 90, color: Colors.red),
            const SizedBox(height: 10),
            const Text(
              'SOS ACTIVE',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 6),
            Text('Active for ${_format(_seconds)}'),

            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help is on the way',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  SizedBox(height: 6),
                  Text('• Live location is being shared'),
                  Text('• Emergency contacts are alerted'),
                ],
              ),
            ),

            if (_isOffline)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'ℹ️ Nearby maps may still be visible using offline data.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 28),

            if (latitude != null && longitude != null)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(
                        icon: Icons.local_police,
                        label: 'Call Police',
                        color: Colors.blue,
                        onTap: () => _callNumber('112'),
                      ),
                      _actionButton(
                        icon: Icons.local_hospital,
                        label: 'Call Ambulance',
                        color: Colors.green,
                        onTap: () => _callNumber('108'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(
                        icon: Icons.location_on,
                        label: 'Nearby Police',
                        color: Colors.indigo,
                        onTap: () =>
                            NearbyHelpService.openPolice(latitude!, longitude!),
                      ),
                      _actionButton(
                        icon: Icons.location_on,
                        label: 'Nearby Hospital',
                        color: Colors.teal,
                        onTap: () =>
                            NearbyHelpService.openHospital(latitude!, longitude!),
                      ),
                    ],
                  ),
                ],
              ),

            const Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _stopEmergency,
              child: const Text(
                'STOP EMERGENCY',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔘 ACTION BUTTON
  // ============================================================
  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 150,
      height: 90,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🧮 CALCULATOR UI
  // ============================================================
  Widget _buildCalculator() {
    return WillPopScope(
      onWillPop: () async {
        setState(() => _isHidden = false);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.centerRight,
              child: Text(
                _display,
                style: const TextStyle(
                  fontSize: 56,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const Text(
              'Long press any key to exit',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const Spacer(),
            _calcRow(['AC', '⌫', '÷', '×']),
            _calcRow(['7', '8', '9', '-']),
            _calcRow(['4', '5', '6', '+']),
            _calcRow(['1', '2', '3', '=']),
            _calcRow(['0']),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _calcRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) {
        return GestureDetector(
          onTap: () => _onKeyTap(k),
          onLongPress: () => setState(() => _isHidden = false),
          child: Container(
            margin: const EdgeInsets.all(8),
            width: k == '0' ? 160 : 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(36),
            ),
            alignment: Alignment.center,
            child: Text(
              k,
              style: const TextStyle(fontSize: 26, color: Colors.white70),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _format(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}
