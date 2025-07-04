// core/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  double _fontSize = 16.0;
  bool _highContrast = false;

  SettingsProvider() {
    _loadSettings();
  }

  double get fontSize => _fontSize;
  bool get highContrast => _highContrast;

  void setFontSize(double value) async {
    _fontSize = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', value);
  }

  void setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highContrast', value);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    _highContrast = prefs.getBool('highContrast') ?? false;
    notifyListeners();
  }
} 