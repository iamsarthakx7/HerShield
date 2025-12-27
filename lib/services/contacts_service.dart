import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactsService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;

  /// ➕ Add contact (max 5)
  static Future<void> addContact({
    required String name,
    required String phone,
  }) async {
    final contactsRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('contacts');

    final snapshot = await contactsRef.get();
    if (snapshot.docs.length >= 5) {
      throw Exception('Maximum 5 emergency contacts allowed');
    }

    await contactsRef.add({
      'name': name,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 📥 Get contacts stream
  static Stream<QuerySnapshot> getContacts() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('contacts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ❌ Delete contact
  static Future<void> deleteContact(String contactId) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('contacts')
        .doc(contactId)
        .delete();
  }
}
