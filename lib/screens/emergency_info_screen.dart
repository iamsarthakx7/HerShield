import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyInfoScreen extends StatefulWidget {
  const EmergencyInfoScreen({super.key});

  @override
  State<EmergencyInfoScreen> createState() => _EmergencyInfoScreenState();
}

class _EmergencyInfoScreenState extends State<EmergencyInfoScreen> {
  final _bloodController = TextEditingController();
  final _allergyController = TextEditingController();
  final _medicalController = TextEditingController();
  final _noteController = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();
    if (data != null) {
      _bloodController.text = data['bloodGroup'] ?? '';
      _allergyController.text = data['allergy'] ?? '';
      _medicalController.text = data['medicalNotes'] ?? '';
      _noteController.text = data['emergencyNote'] ?? '';
    }

    setState(() => _loading = false);
  }

  Future<void> _saveData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'bloodGroup': _bloodController.text.trim(),
      'allergy': _allergyController.text.trim(),
      'medicalNotes': _medicalController.text.trim(),
      'emergencyNote': _noteController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency info updated')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Info'),
        backgroundColor: Colors.red,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _field('Blood Group', _bloodController),
            _field('Allergies', _allergyController),
            _field('Medical Conditions', _medicalController, max: 3),
            _field('Emergency Note', _noteController, max: 3),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
      String label,
      TextEditingController controller, {
        int max = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: max,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
