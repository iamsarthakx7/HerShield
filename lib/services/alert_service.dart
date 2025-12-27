import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      final phone = contact['phone'];

      final alertMessage = '''
🚨 EMERGENCY ALERT 🚨

Name: $userName
Location: $mapsLink

Please respond immediately.
''';

      // 🔥 STORE alert (SMS/WhatsApp ready)
      await _firestore.collection('alerts').add({
        'userId': user.uid,
        'userName': userName,
        'contactName': contactName,
        'phone': phone,
        'message': alertMessage,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // For now → debug output
      print('ALERT SENT TO $contactName ($phone)');
    }
  }
}
