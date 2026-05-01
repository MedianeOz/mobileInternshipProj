import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CyberShield Home'),
      ),
      body: const Center(
        child: Text('Welcome to CyberShield'),
      ),
    );
  }
}
