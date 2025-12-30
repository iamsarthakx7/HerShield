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
  // 🚨 MAIN ENTRY POINT
  // ===============================
  Future<void> sendSOSAlert({
    required double latitude,
    required double longitude,
  }) async {
    // ✅ Save location persistently
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
      try {
        await _sendOnline(baseMessage);
      } catch (_) {
        // 🔥 HARD FALLBACK
        await _sendOfflineSMS(baseMessage);
      }
    } else {
      // 📵 PURE OFFLINE
      await _sendOfflineSMS(baseMessage);
    }
  }

  // ===============================
  // 💾 SAVE LOCATION (PERSISTENT)
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
  // ⏱ HUMAN-READABLE TIME
  // ===============================
  Future<String> _getLastUpdatedText() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('last_location_time');

    if (ts == null) return 'just now';

    final diff =
    DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute(s) ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour(s) ago';
    } else {
      return '${diff.inDays} day(s) ago';
    }
  }

  // ===============================
  // 🌐 ONLINE MODE
  // ===============================
  Future<void> _sendOnline(String baseMessage) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc =
    await _firestore.collection('users').doc(user.uid).get();

    final userName = userDoc.data()?['name'] ?? 'Unknown';
    final fullMessage = 'Name: $userName\n\n$baseMessage';

    final contactsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('contacts')
        .get();

    for (var contact in contactsSnapshot.docs) {
      final rawPhone = contact['phone'];
      final phone = rawPhone.replaceAll('+', '').replaceAll(' ', '');

      // 📩 SMS (ALWAYS)
      await _sendSMS(phone, fullMessage);

      // 📲 WhatsApp (BEST EFFORT)
      try {
        await WhatsAppService.openWhatsApp(
          phone: phone,
          message: fullMessage,
        );
      } catch (_) {}

      // 🔥 Log alert (non-blocking)
      try {
        await _firestore.collection('alerts').add({
          'userId': user.uid,
          'contactName': contact['name'],
          'phone': rawPhone,
          'message': fullMessage,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  // ===============================
  // 📵 OFFLINE MODE (CRITICAL)
  // ===============================
  Future<void> _sendOfflineSMS(String message) async {
    final offlineContacts =
    await ContactsService.getOfflineContacts();

    for (var contact in offlineContacts) {
      final phone =
      contact['phone']!.replaceAll('+', '').replaceAll(' ', '');

      await _sendSMS(phone, message);
    }
  }

  // ===============================
  // 📩 SMS SENDER (OFFLINE SAFE)
  // ===============================
  Future<void> _sendSMS(String phone, String message) async {
    final uri = Uri.parse(
      'sms:$phone?body=${Uri.encodeComponent(message)}',
    );

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('SMS launch failed: $e');
    }
  }

  // ===============================
  // 🌐 FAST INTERNET CHECK
  // ===============================
  Future<bool> _checkInternet() async {
    try {
      final result =
      await InternetAddress.lookup('google.com');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
