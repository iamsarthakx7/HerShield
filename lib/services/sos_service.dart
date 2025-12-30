import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // 🚨 START SOS (CREATE OR REUSE EVENT)
  // ============================================================
  Future<String> startSOS({
    required double latitude,
    required double longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // ✅ Use cached location if needed
    final resolvedLocation =
    await _resolveLocation(latitude, longitude);

    // 🔁 Reuse existing active SOS if present
    final activeSnapshot = await _firestore
        .collection('sos_events')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (activeSnapshot.docs.isNotEmpty) {
      return activeSnapshot.docs.first.id;
    }

    final docRef = await _firestore.collection('sos_events').add({
      'userId': user.uid,
      'email': user.email,
      'status': 'active',
      'latitude': resolvedLocation['lat'],
      'longitude': resolvedLocation['lng'],
      'locationSource': resolvedLocation['source'], // live / cached
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLocationUpdatedAt': FieldValue.serverTimestamp(),
      'endedAt': null,
    });

    return docRef.id;
  }

  // ============================================================
  // 📍 UPDATE LIVE LOCATION (WITH CACHE FALLBACK)
  // ============================================================
  Future<void> updateLocation({
    required String sosId,
    required double latitude,
    required double longitude,
  }) async {
    final resolvedLocation =
    await _resolveLocation(latitude, longitude);

    await _firestore.collection('sos_events').doc(sosId).update({
      'latitude': resolvedLocation['lat'],
      'longitude': resolvedLocation['lng'],
      'locationSource': resolvedLocation['source'],
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLocationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // 🧠 LOCATION RESOLUTION (LIVE → CACHE)
  // ============================================================
  Future<Map<String, dynamic>> _resolveLocation(
      double lat,
      double lng,
      ) async {
    // ✅ Valid live location
    if (!_isInvalid(lat, lng)) {
      await _saveLastLocation(lat, lng);
      return {
        'lat': lat,
        'lng': lng,
        'source': 'live',
      };
    }

    // 🧠 Fallback to cache
    final prefs = await SharedPreferences.getInstance();
    final cachedLat = prefs.getDouble('last_lat');
    final cachedLng = prefs.getDouble('last_lng');

    if (cachedLat != null && cachedLng != null) {
      return {
        'lat': cachedLat,
        'lng': cachedLng,
        'source': 'cached',
      };
    }

    throw Exception('No valid location available');
  }

  bool _isInvalid(double lat, double lng) {
    return lat == 0.0 || lng == 0.0;
  }

  // ============================================================
  // 💾 SAVE LOCATION PERSISTENTLY
  // ============================================================
  Future<void> _saveLastLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_lat', lat);
    await prefs.setDouble('last_lng', lng);
    await prefs.setInt(
      'last_location_time',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ============================================================
  // 🛑 STOP SOS (END EVENT)
  // ============================================================
  Future<void> stopSOS(String sosId) async {
    await _firestore.collection('sos_events').doc(sosId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // 🔥 AUTO-CLOSE ANY STUCK ACTIVE SOS
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
