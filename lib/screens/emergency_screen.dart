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

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  Timer? _uiTimer;
  Timer? _locationTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  int _seconds = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

  // Scroll controller for action buttons
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;

  // ============================================================
  // 🔁 INIT
  // ============================================================
  @override
  void initState() {
    super.initState();

    // Pulse animation for SOS indicator
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

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

    // Listen to scroll position
    _scrollController.addListener(_updatePageIndicator);

    // Auto scroll hint after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          100,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _locationTimer?.cancel();
    _connectivitySub?.cancel();
    _pulseController.dispose();
    _scrollController.removeListener(_updatePageIndicator);
    _scrollController.dispose();
    super.dispose();
  }

  // Update page indicator based on scroll position
  void _updatePageIndicator() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final newPage = (offset / 172).round();

    if (newPage != _currentPage && mounted) {
      setState(() {
        _currentPage = newPage;
      });
    }
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
        title: const Text(
          'Emergency Mode',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFFDC2626),
        centerTitle: true,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.visibility_off_outlined,
                size: 22,
              ),
              onPressed: () => setState(() => _isHidden = true),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // SOS Indicator with pulse
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFEF4444).withOpacity(0.3),
                              const Color(0xFFDC2626).withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFEF4444),
                                  Color(0xFFDC2626),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.warning_rounded,
                              size: 35,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Active SOS Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFECACA),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'SOS ACTIVE',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Active for ${_format(_seconds)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Status Information Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFBBF7D0),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF16A34A),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Help is on the way',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _compactStatusItem('Live location shared'),
                            _compactStatusItem('Contacts alerted'),
                            _compactStatusItem('Responders notified'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isOffline)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEFCE8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFEF08A),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.signal_wifi_off_rounded,
                          color: const Color(0xFFCA8A04),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Using offline location data',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFFCA8A04),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Scrollable Action Buttons Section with Visual Indicator
                Container(
                  height: 240, // Fixed height to indicate more content
                  child: Column(
                    children: [
                      // Section Title with Scroll Indicator
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swipe_down_rounded,
                              color: Colors.grey[600],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Swipe for more options',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scrollable Action Buttons
                      Expanded(
                        child: ListView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            const SizedBox(width: 8),
                            // First two buttons (Police & Ambulance)
                            if (latitude != null && longitude != null) ...[
                              _horizontalActionButton(
                                icon: Icons.local_police_rounded,
                                label: 'Police',
                                subtitle: 'Call 112',
                                color: const Color(0xFF3B82F6),
                                onTap: () => _callNumber('112'),
                              ),
                              const SizedBox(width: 12),
                              _horizontalActionButton(
                                icon: Icons.local_hospital_rounded,
                                label: 'Ambulance',
                                subtitle: 'Call 108',
                                color: const Color(0xFF10B981),
                                onTap: () => _callNumber('108'),
                              ),
                              const SizedBox(width: 12),
                              // Last two buttons (Police Nearby & Hospitals Nearby)
                              _horizontalActionButton(
                                icon: Icons.location_pin,
                                label: 'Police Stations',
                                subtitle: 'Find Nearby',
                                color: const Color(0xFF6366F1),
                                onTap: () => NearbyHelpService.openPolice(latitude!, longitude!),
                              ),
                              const SizedBox(width: 12),
                              _horizontalActionButton(
                                icon: Icons.medical_services_rounded,
                                label: 'Hospitals',
                                subtitle: 'Find Nearby',
                                color: const Color(0xFF8B5CF6),
                                onTap: () => NearbyHelpService.openHospital(latitude!, longitude!),
                              ),
                            ] else ...[
                              // Loading state
                              Container(
                                width: MediaQuery.of(context).size.width - 40,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Color(0xFFDC2626),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Getting location...',
                                      style: TextStyle(
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),

                      // Page Indicator Dots
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPageIndicator(0),
                            const SizedBox(width: 8),
                            _buildPageIndicator(1),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stop Emergency Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _stopEmergency,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_circle_outlined, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'STOP EMERGENCY',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactStatusItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔘 HORIZONTAL SCROLLABLE ACTION BUTTON
  // ============================================================
  Widget _horizontalActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 160, // Wider for better tap area
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Page Indicator Dot
  Widget _buildPageIndicator(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? const Color(0xFFDC2626)
            : Colors.grey[300],
      ),
    );
  }

  // ============================================================
  // 🧮 CALCULATOR UI (STEALTH MODE)
  // ============================================================
  Widget _buildCalculator() {
    return WillPopScope(
      onWillPop: () async {
        setState(() => _isHidden = false);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.centerRight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    _display,
                    style: const TextStyle(
                      fontSize: 56,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Calculator • Long press any key to exit',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              _calcRow(['AC', '⌫', '÷', '×']),
              _calcRow(['7', '8', '9', '-']),
              _calcRow(['4', '5', '6', '+']),
              _calcRow(['1', '2', '3', '=']),
              _calcRow(['0']),
              const SizedBox(height: 40),
            ],
          ),
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
              color: k == 'AC' || k == '⌫'
                  ? const Color(0xFF475569)
                  : k == '÷' || k == '×' || k == '-' || k == '+' || k == '='
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF334155),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              k,
              style: const TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _format(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}