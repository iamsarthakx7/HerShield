import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔥 Start SOS (Create Firestore document)
  Future<String> startSOS({
    required double latitude,
    required double longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final docRef = await _firestore.collection('sos_events').add({
      'userId': user.uid,
      'email': user.email,
      'status': 'active',
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// 📍 Update live location
  Future<void> updateLocation({
    required String sosId,
    required double latitude,
    required double longitude,
  }) async {
    await _firestore.collection('sos_events').doc(sosId).update({
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🛑 Stop SOS
  Future<void> stopSOS(String sosId) async {
    await _firestore.collection('sos_events').doc(sosId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }
}
