import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'whatsapp_service.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 Send alert to all emergency contacts
  Future<void> sendSOSAlert({
    required double latitude,
    required double longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1️⃣ Fetch user profile
    final userDoc =
    await _firestore.collection('users').doc(user.uid).get();

    final userName = userDoc.data()?['name'] ?? 'Unknown';

    final mapsLink =
        'https://www.google.com/maps?q=$latitude,$longitude';

    // 2️⃣ Fetch emergency contacts
    final contactsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('contacts')
        .get();

    for (var contact in contactsSnapshot.docs) {
      final contactName = contact['name'];
      final rawPhone = contact['phone'];

      // ✅ WhatsApp requires country code WITHOUT +
      final phone = rawPhone.replaceAll('+', '').replaceAll(' ', '');

      final alertMessage = '''
🚨 EMERGENCY ALERT 🚨

$userName needs help immediately!

📍 Location:
$mapsLink

Please respond ASAP.
''';

      // 🔥 Store alert in Firestore (for logs / demo)
      await _firestore.collection('alerts').add({
        'userId': user.uid,
        'userName': userName,
        'contactName': contactName,
        'phone': rawPhone,
        'message': alertMessage,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 📲 Open WhatsApp with prefilled message
      try {
        await WhatsAppService.openWhatsApp(
          phone: phone,
          message: alertMessage,
        );
      } catch (e) {
        print('WhatsApp failed for $contactName: $e');
      }

      // 🧪 Debug log
      print('ALERT PROCESSED FOR $contactName ($rawPhone)');
    }
  }
}
