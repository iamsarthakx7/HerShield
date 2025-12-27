import 'package:flutter/material.dart';

void main() {
  runApp(const HerShieldApp());
}

class HerShieldApp extends StatelessWidget {
  const HerShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HerShield',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'HerShield – Women Safety App',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
