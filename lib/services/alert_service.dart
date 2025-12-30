import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'contacts_service.dart';
import 'whatsapp_service.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===============================
  // 🚨 MAIN ENTRY POINT (SAFE)
  // ===============================
  Future<void> sendSOSAlert({
    required double latitude,
    required double longitude,
  }) async {
    await _saveLastLocation(latitude, longitude);

    final mapsLink =
        'https://www.google.com/maps?q=$latitude,$longitude';

    final lastUpdatedText = await _getLastUpdatedText();

    final baseMessage = '''
🚨 EMERGENCY ALERT 🚨

I need help immediately!

📍 Location:
$mapsLink

⏱ Last updated: $lastUpdatedText
''';

    final hasInternet = await _checkInternet();

    if (hasInternet) {
      final success = await _tryWhatsAppFirst(baseMessage);
      if (!success) {
        await _sendOfflineSMS(baseMessage);
      }
    } else {
      await _sendOfflineSMS(baseMessage);
    }
  }

  // ===============================
  // 🟢 WHATSAPP PRIORITY (SAFE)
  // ===============================
  Future<bool> _tryWhatsAppFirst(String baseMessage) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc =
      await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Unknown';

      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('contacts')
          .get();

      if (contactsSnapshot.docs.isEmpty) return false;

      final buffer = StringBuffer();
      buffer.writeln('Name: $userName\n');
      buffer.writeln(baseMessage);
      buffer.writeln('\n📞 Emergency Contacts:');

      for (var c in contactsSnapshot.docs) {
        buffer.writeln('• ${c['name']} (${c['phone']})');
      }

      // 🚀 SINGLE WhatsApp launch (CRITICAL FIX)
      await WhatsAppService.openWhatsApp(
        phone: contactsSnapshot.docs.first['phone']
            .replaceAll('+', '')
            .replaceAll(' ', ''),
        message: buffer.toString(),
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  // ===============================
  // 📵 SMS FALLBACK (SAFE)
  // ===============================
  Future<void> _sendOfflineSMS(String message) async {
    final contacts = await ContactsService.getOfflineContacts();

    for (var contact in contacts) {
      final phone =
      contact['phone']!.replaceAll('+', '').replaceAll(' ', '');

      await _sendSMS(phone, message);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // ===============================
  // 📩 SMS SENDER
  // ===============================
  Future<void> _sendSMS(String phone, String message) async {
    final uri = Uri.parse(
      'sms:$phone?body=${Uri.encodeComponent(message)}',
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ===============================
  // 💾 SAVE LOCATION
  // ===============================
  Future<void> _saveLastLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_lat', lat);
    await prefs.setDouble('last_lng', lng);
    await prefs.setInt(
      'last_location_time',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ===============================
  // ⏱ HUMAN TIME
  // ===============================
  Future<String> _getLastUpdatedText() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('last_location_time');

    if (ts == null) return 'just now';

    final diff =
    DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minute(s) ago';
    if (diff.inHours < 24) return '${diff.inHours} hour(s) ago';
    return '${diff.inDays} day(s) ago';
  }

  // ===============================
  // 🌐 INTERNET CHECK
  // ===============================
  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
