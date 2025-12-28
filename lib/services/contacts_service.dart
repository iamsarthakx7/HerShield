import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  static const String _localContactsKey =
      'offline_emergency_contacts';

  /// ➕ Add contact (Firebase + Local backup)
  static Future<void> addContact({
    required String name,
    required String phone,
  }) async {
    if (_uid == null) return;

    final contactsRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('contacts');

    final snapshot = await contactsRef.get();
    if (snapshot.docs.length >= 5) {
      throw Exception('Maximum 5 emergency contacts allowed');
    }

    // 🔥 Save to Firebase
    await contactsRef.add({
      'name': name,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 📱 Save locally (offline backup)
    await _saveContactLocally(name, phone);
  }

  /// 📡 ONLINE CONTACTS (for UI)
  static Stream<QuerySnapshot> getContacts() {
    if (_uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('contacts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 💾 Save contact locally (NO DUPLICATES)
  static Future<void> _saveContactLocally(
      String name,
      String phone,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> stored =
        prefs.getStringList(_localContactsKey) ?? [];

    // ❌ Prevent duplicate phone numbers
    final alreadyExists = stored.any((e) {
      final data = jsonDecode(e);
      return data['phone'] == phone;
    });

    if (alreadyExists) return;

    stored.add(jsonEncode({
      'name': name,
      'phone': phone,
    }));

    await prefs.setStringList(_localContactsKey, stored);
  }

  /// 📥 OFFLINE CONTACTS (USED BY SOS WHEN NO INTERNET)
  static Future<List<Map<String, String>>> getOfflineContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final stored =
        prefs.getStringList(_localContactsKey) ?? [];

    return stored
        .map((e) => Map<String, String>.from(jsonDecode(e)))
        .toList();
  }

  /// ❌ Delete contact (Firebase + Local)
  static Future<void> deleteContact({
    required String contactId,
    required String phone,
  }) async {
    if (_uid == null) return;

    // 🔥 Remove from Firebase
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('contacts')
        .doc(contactId)
        .delete();

    // 📱 Remove from local storage
    final prefs = await SharedPreferences.getInstance();
    final stored =
        prefs.getStringList(_localContactsKey) ?? [];

    stored.removeWhere((e) {
      final data = jsonDecode(e);
      return data['phone'] == phone;
    });

    await prefs.setStringList(_localContactsKey, stored);
  }
}
