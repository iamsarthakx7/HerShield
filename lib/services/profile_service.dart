import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static String get _uid => _auth.currentUser!.uid;

  // 🔹 Update name
  static Future<void> updateName(String name) async {
    await _firestore.collection('users').doc(_uid).update({
      'name': name,
    });
  }

  // 🔹 Update email (Firebase Auth)
  static Future<void> updateEmail(String email) async {
    await _auth.currentUser!.updateEmail(email);
    await _firestore.collection('users').doc(_uid).update({
      'email': email,
    });
  }

  // 🔹 Upload profile photo
  static Future<String> uploadProfileImage(File file) async {
    final ref = _storage.ref().child('profile_photos/$_uid.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await _firestore.collection('users').doc(_uid).update({
      'photoUrl': url,
    });

    return url;
  }
}
