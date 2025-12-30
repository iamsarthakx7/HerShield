import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _bloodController = TextEditingController();
  final _noteController = TextEditingController();

  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  bool _loading = false;
  List<Map<String, String>> _contacts = [];

  void _addContact() {
    if (_contactNameController.text.trim().isEmpty ||
        _contactPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter contact name and phone')),
      );
      return;
    }

    if (_contacts.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 contacts allowed')),
      );
      return;
    }

    setState(() {
      _contacts.add({
        'name': _contactNameController.text.trim(),
        'phone': _contactPhoneController.text.trim(),
      });
    });

    _contactNameController.clear();
    _contactPhoneController.clear();
  }

  void _removeContact(int index) {
    setState(() => _contacts.removeAt(index));
  }

  Future<void> _completeProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.trim().isEmpty ||
        _bloodController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    if (_contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one emergency contact'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final userRef =
    FirebaseFirestore.instance.collection('users').doc(user.uid);

    await userRef.set({
      'name': _nameController.text.trim(),
      'bloodGroup': _bloodController.text.trim(),
      'emergencyNote': _noteController.text.trim(),
      'profileCompleted': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    for (final contact in _contacts) {
      await userRef.collection('contacts').add({
        'name': contact['name'],
        'phone': contact['phone'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() => _loading = false);

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This information is required for your safety',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _bloodController,
              decoration: const InputDecoration(
                labelText: 'Blood Group *',
                prefixIcon: Icon(Icons.bloodtype),
                hintText: 'A+, B-, O+',
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Emergency Note (optional)',
                prefixIcon: Icon(Icons.medical_information),
              ),
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 15),

            const Text(
              'Emergency Contacts (1–5 required)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _contactNameController,
              decoration: const InputDecoration(
                labelText: 'Contact Name',
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _contactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Phone',
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _addContact,
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),

            const SizedBox(height: 15),

            ..._contacts.asMap().entries.map((entry) {
              final index = entry.key;
              final contact = entry.value;

              return ListTile(
                leading: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                ),
                title: Text(contact['name']!),
                subtitle: Text(contact['phone']!),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: AppColors.emergency,
                  ),
                  onPressed: () => _removeContact(index),
                ),
              );
            }),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _completeProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const CircularProgressIndicator(
                  color: AppColors.white,
                )
                    : const Text(
                  'Finish Setup',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
