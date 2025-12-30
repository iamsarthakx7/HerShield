import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/sos_service.dart';

class SOSHistoryScreen extends StatelessWidget {
  const SOSHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'SOS History',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: SosService().getSosHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _EmptyHistoryState();
          }

          final docs = snapshot.data!.docs;
          final sosCount = docs.length;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.1),
                          const Color(0xFF8B5CF6).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.history_toggle_off_rounded,
                            color: Color(0xFF6366F1),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Emergency History',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$sosCount SOS alert${sosCount != 1 ? 's' : ''} recorded',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // History List
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final double? lat = (data['latitude'] as num?)?.toDouble();
                    final double? lng = (data['longitude'] as num?)?.toDouble();
                    final Timestamp? endedAt = data['endedAt'] as Timestamp?;
                    final Timestamp? startedAt =
                    data['createdAt'] as Timestamp?;
                    final String? status = data['status'] as String?;
                    final bool isActive = status == 'active';

                    return _SOSHistoryCard(
                      lat: lat,
                      lng: lng,
                      startedAt: startedAt,
                      endedAt: endedAt,
                      isActive: isActive,
                    );
                  }),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===============================
  // 🗺️ STATIC MAP PREVIEW
  // ===============================
  static String staticMapUrl(double lat, double lng) {
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=16'
        '&size=600x300'
        '&scale=2'
        '&markers=color:red%7C$lat,$lng'
        '&key=YOUR_MAPS_API_KEY'; // Replace with your API key
  }

  // ===============================
  // 📍 OPEN GOOGLE MAPS
  // ===============================
  static Future<void> openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  // ===============================
  // 🕒 FRIENDLY DATE FORMAT
  // ===============================
  static String _prettyDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';

    final dt = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;

    final time = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';

    if (diff == 0) {
      return 'Today at $time';
    } else if (diff == 1) {
      return 'Yesterday at $time';
    } else if (diff < 7) {
      return '${_weekday(dt.weekday)} at $time';
    } else {
      return '${dt.day}/${dt.month}/${dt.year} at $time';
    }
  }

  static String _weekday(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  // ===============================
  // ⏱️ DURATION CALCULATION
  // ===============================
  static String _calculateDuration(Timestamp? startedAt, Timestamp? endedAt) {
    if (startedAt == null || endedAt == null) return 'Unknown duration';

    final start = startedAt.toDate();
    final end = endedAt.toDate();
    final duration = end.difference(start);

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes == 0) {
      return '$seconds seconds';
    } else if (seconds == 0) {
      return '$minutes minutes';
    } else {
      return '$minutes min $seconds sec';
    }
  }
}

// ===============================
// 🗺️ SOS HISTORY CARD
// ===============================
class _SOSHistoryCard extends StatelessWidget {
  final double? lat;
  final double? lng;
  final Timestamp? startedAt;
  final Timestamp? endedAt;
  final bool isActive;

  const _SOSHistoryCard({
    this.lat,
    this.lng,
    this.startedAt,
    this.endedAt,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Preview Section
          if (lat != null && lng != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Container(
                height: 180,
                width: double.infinity,
                color: const Color(0xFFF1F5F9),
                child: Stack(
                  children: [
                    // Map Preview
                    Image.network(
                      SOSHistoryScreen.staticMapUrl(lat!, lng!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.map_rounded,
                              color: Color(0xFF94A3B8),
                              size: 50,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Location: ${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Location Pin
                    Positioned(
                      top: 80,
                      left: MediaQuery.of(context).size.width / 2 - 15,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Emergency Alert',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    _StatusBadge(isActive: isActive),
                  ],
                ),

                const SizedBox(height: 12),

                // Time Information
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (startedAt != null)
                      _infoRow(
                        icon: Icons.timer_outlined,
                        text: 'Started: ${SOSHistoryScreen._prettyDate(startedAt!)}',
                      ),
                    if (endedAt != null)
                      _infoRow(
                        icon: Icons.check_circle_outline_rounded,
                        text: 'Ended: ${SOSHistoryScreen._prettyDate(endedAt!)}',
                      ),
                    if (startedAt != null && endedAt != null)
                      _infoRow(
                        icon: Icons.access_time_rounded,
                        text:
                        'Duration: ${SOSHistoryScreen._calculateDuration(startedAt, endedAt)}',
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Button
                if (lat != null && lng != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.open_in_new_rounded,
                        size: 18,
                      ),
                      label: const Text('Open in Google Maps'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: const Color(0xFF6366F1),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () =>
                          SOSHistoryScreen.openGoogleMaps(lat!, lng!),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF64748B),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// 🟢 STATUS BADGE
// ===============================
class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFDE68A)
              : const Color(0xFF86EFAC),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
          ),
          Text(
            isActive ? 'ACTIVE' : 'RESOLVED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? const Color(0xFF92400E)
                  : const Color(0xFF166534),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// 📦 EMPTY HISTORY STATE
// ===============================
class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                color: Color(0xFF94A3B8),
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No SOS History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your emergency alerts will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: const Color(0xFF6366F1),
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Stay safe! Use SOS only for genuine emergencies',
                      style: TextStyle(
                        color: const Color(0xFF475569),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}