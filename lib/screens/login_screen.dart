import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool loading = false;
  bool isRegisterMode = false;

  // 🔐 LOGIN EXISTING USER
  Future<void> _login() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('Please enter email and password');
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Navigation handled by authStateChanges() in main.dart
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Login failed');
    }

    setState(() => loading = false);
  }

  // 🆕 REGISTER NEW USER
  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('All fields are required');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showMessage('Password must be at least 6 characters');
      return;
    }

    setState(() => loading = true);

    try {
      // 1️⃣ Create Firebase Auth user
      UserCredential credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user!;

      // 2️⃣ Save display name in Firebase Auth
      await user.updateDisplayName(_nameController.text.trim());

      // 3️⃣ Save user profile in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔁 Switch back to login mode
      setState(() {
        isRegisterMode = false;
      });

      _showMessage('Account created successfully. Please login.');

    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Registration failed');
    }

    setState(() => loading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isRegisterMode ? 'Register' : 'Login'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.security, size: 80, color: Colors.red),
            const SizedBox(height: 30),

            // 👤 Name (Register only)
            if (isRegisterMode)
              Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // 📧 Email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // 🔑 Password
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            // 🔘 Primary Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: loading
                  ? null
                  : isRegisterMode
                  ? _register
                  : _login,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isRegisterMode ? 'Create Account' : 'Login'),
            ),

            const SizedBox(height: 10),

            // 🔁 Switch Mode
            TextButton(
              onPressed: () {
                setState(() {
                  isRegisterMode = !isRegisterMode;
                });
              },
              child: Text(
                isRegisterMode
                    ? 'Already have an account? Login'
                    : 'New user? Create account',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
