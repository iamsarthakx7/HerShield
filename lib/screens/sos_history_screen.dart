import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../services/sos_service.dart';

class SOSHistoryScreen extends StatelessWidget {
  const SOSHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS History'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: SosService().getSosHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No SOS history found',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
              docs[index].data() as Map<String, dynamic>;

              final double? lat =
              (data['latitude'] as num?)?.toDouble();
              final double? lng =
              (data['longitude'] as num?)?.toDouble();
              final Timestamp? endedAt =
              data['endedAt'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🗺️ MAP PREVIEW
                    if (lat != null && lng != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          staticMapUrl(lat, lng),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.map, size: 40),
                            ),
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🚨 SOS Emergency',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          if (endedAt != null)
                            Text(
                              'Ended on: ${_formatDate(endedAt)}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),

                          const SizedBox(height: 10),

                          if (lat != null && lng != null)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  openGoogleMaps(lat, lng);
                                },
                                icon: const Icon(Icons.location_on),
                                label:
                                const Text('View on Google Maps'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ===============================
  // 🗺️ STATIC MAP PREVIEW
  // ===============================
  String staticMapUrl(double lat, double lng) {
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=15'
        '&size=600x300'
        '&markers=color:red|$lat,$lng';
  }

  // ===============================
  // 📍 OPEN GOOGLE MAPS
  // ===============================
  Future<void> openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  // ===============================
  // 🕒 DATE FORMAT (NO intl needed)
  // ===============================
  String _formatDate(Timestamp timestamp) {
    final dt = timestamp.toDate();
    return '${dt.day}/${dt.month}/${dt.year} • '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
