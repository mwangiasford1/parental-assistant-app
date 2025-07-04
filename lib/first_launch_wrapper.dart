import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/welcome/welcome_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

class FirstLaunchWrapper extends StatefulWidget {
  const FirstLaunchWrapper({super.key});

  @override
  State<FirstLaunchWrapper> createState() => _FirstLaunchWrapperState();
}

class _FirstLaunchWrapperState extends State<FirstLaunchWrapper> {
  bool? _firstLaunch;
  bool _showOnboarding = false;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_welcome') ?? false;
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    setState(() {
      _firstLaunch = !seen;
      _showOnboarding = !seenOnboarding && !seen;
    });
    if (!seen) {
      await prefs.setBool('seen_welcome', true);
    }
  }

  void _onWelcomeComplete() {
    setState(() {
      _showOnboarding = true;
    });
  }

  void _onOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    setState(() {
      _showRegister = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_firstLaunch == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_showRegister) {
      return const LoginScreen(
        key: ValueKey('register'),
        initialIsLogin: false,
      );
    }
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }
    if (!_firstLaunch!) {
      return const LoginScreen(key: ValueKey('login'), initialIsLogin: true);
    }
    return WelcomeScreen(onGetStarted: _onWelcomeComplete);
  }
}
