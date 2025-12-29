import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_profile_screen.dart';
import 'sos_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.red,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'SOS History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SOSHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>?;

          final name = data?['name'] ?? 'User';
          final email = user.email ?? 'Not available';
          final photoUrl = data?['photoUrl'];
          final bloodGroup = data?['bloodGroup'] ?? 'Not specified';
          final emergencyNote =
              data?['emergencyNote'] ?? 'No emergency note added';

          return SingleChildScrollView(
            child: Column(
              children: [
                // 🔴 HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.red,
                        )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // 📄 INFO CARDS
                _infoCard(
                  icon: Icons.bloodtype,
                  title: 'Blood Group',
                  value: bloodGroup,
                ),

                _infoCard(
                  icon: Icons.medical_information,
                  title: 'Emergency Note',
                  value: emergencyNote,
                ),

                const SizedBox(height: 25),

                // ✏️ EDIT PROFILE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(
                              currentName: name,
                              currentEmail: email,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🧱 REUSABLE INFO CARD
  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.red),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
