import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🚨 START SOS (CREATE EVENT)
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
      'endedAt': null,
    });

    return docRef.id;
  }

  /// 📍 UPDATE LIVE LOCATION
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

  /// 🛑 STOP SOS (END EVENT)
  Future<void> stopSOS(String sosId) async {
    await _firestore.collection('sos_events').doc(sosId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // 🔥 AUTO-CLOSE ANY STUCK ACTIVE SOS (CRITICAL FIX)
  // ============================================================
  Future<void> closeAnyActiveSOS() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('sos_events')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ============================================================
  // 📜 SOS HISTORY (ENDED EVENTS ONLY)
  // ============================================================
  Stream<QuerySnapshot> getSosHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('sos_events')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'ended')
        .orderBy('endedAt', descending: true)
        .snapshots();
  }
}