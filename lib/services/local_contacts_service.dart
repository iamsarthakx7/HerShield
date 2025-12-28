import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalContactsService {
  static const String _key = 'emergency_contacts';

  /// ➕ Save contact locally (offline-safe)
  static Future<void> saveContact({
    required String name,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final List<Map<String, String>> contacts =
    await getContacts();

    contacts.add({
      'name': name,
      'phone': phone,
    });

    await prefs.setString(_key, jsonEncode(contacts));
  }

  /// 📥 Get local contacts
  static Future<List<Map<String, String>>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);

    if (data == null) return [];

    final List decoded = jsonDecode(data);
    return decoded
        .map((e) => Map<String, String>.from(e))
        .toList();
  }

  /// ❌ Clear all (optional)
  static Future<void> clearContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
