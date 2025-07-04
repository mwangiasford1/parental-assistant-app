import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../home/home_screen.dart';

class PostRegistrationWelcomeScreen extends StatelessWidget {
  final UserModel user;
  const PostRegistrationWelcomeScreen({super.key, required this.user});

  String getWelcomeMessage() {
    switch (user.role) {
      case 'child':
        return 'Welcome, Super Kid!\nGet ready for fun, learning, and rewards!';
      case 'nanny':
        return 'Welcome, Caring Nanny!\nYou can help manage schedules and keep kids safe.';
      case 'parent':
      default:
        return 'Welcome, Awesome Parent!\nYou have full control and insights for your family.';
    }
  }

  IconData getRoleIcon() {
    switch (user.role) {
      case 'child':
        return Icons.child_care;
      case 'nanny':
        return Icons.volunteer_activism;
      case 'parent':
      default:
        return Icons.family_restroom;
    }
  }

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
              Icon(getRoleIcon(), size: 100, color: const Color(0xFF4CAF50)),
              const SizedBox(height: 32),
              Text(
                getWelcomeMessage(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
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
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
                    (route) => false,
                  );
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
