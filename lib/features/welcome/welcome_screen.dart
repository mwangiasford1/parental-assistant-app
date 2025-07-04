// features/welcome/welcome_screen.dart
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback? onGetStarted;
  const WelcomeScreen({super.key, this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.family_restroom,
                size: 100,
                color: Color(0xFF4CAF50),
              ),
              const SizedBox(height: 32),
              const Text(
                'Parental Assistant',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Empowering families with smart tools for safety, learning, and fun!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  if (onGetStarted != null) {
                    onGetStarted!();
                  }
                },
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
