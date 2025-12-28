import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';

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

  // 🔐 LOGIN
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
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Login failed');
    }

    setState(() => loading = false);
  }

  // 🆕 REGISTER
  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('All fields are required');
      return;
    }

    setState(() => loading = true);

    try {
      UserCredential credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user!;
      await user.updateDisplayName(_nameController.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => isRegisterMode = false);
      _showMessage('Account created. Please login.');
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Registration failed');
    }

    setState(() => loading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            elevation: 8,
            color: AppColors.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // 🔐 ICON
                  Icon(Icons.security,
                      size: 70, color: AppColors.primary),

                  const SizedBox(height: 16),

                  // 🏷️ TITLE
                  Text(
                    isRegisterMode ? 'Sign Up' : 'Welcome Back',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    isRegisterMode
                        ? 'Create your account'
                        : 'Login to continue',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 30),

                  // 👤 NAME
                  if (isRegisterMode) ...[
                    pinkTextField(
                      controller: _nameController,
                      hint: 'Enter Name',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 📧 EMAIL
                  pinkTextField(
                    controller: _emailController,
                    hint: 'Enter Email',
                    icon: Icons.email,
                  ),

                  const SizedBox(height: 16),

                  // 🔑 PASSWORD
                  pinkTextField(
                    controller: _passwordController,
                    hint: 'Enter Password',
                    icon: Icons.lock,
                    obscureText: true,
                  ),

                  const SizedBox(height: 30),

                  // 🔘 BUTTON
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: loading
                        ? null
                        : isRegisterMode
                        ? _register
                        : _login,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      isRegisterMode ? 'Sign Up' : 'Login',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔁 SWITCH
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
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🌸 SOFT PINK TEXTFIELD
  Widget pinkTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFFEB7C9),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
