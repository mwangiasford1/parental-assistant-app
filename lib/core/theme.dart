// core/theme.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: const Color(0xFF4CAF50),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF212121)),
      bodyMedium: TextStyle(color: Color(0xFF212121)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFFC107),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFFFFC107)),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF212121),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF212121),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFFC107),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
    ),
    colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(secondary: const Color(0xFFFFC107)),
  );

  static ThemeData fromColorAndFont(Color color, String font) {
    return ThemeData(
      primaryColor: color,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: AppBarTheme(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(fontFamily: font, fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: const Color(0xFF212121), fontFamily: font),
        bodyMedium: TextStyle(color: const Color(0xFF212121), fontFamily: font),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFFC107),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFFFFC107)),
      fontFamily: font,
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = AppTheme.lightTheme;
  bool _isDarkMode = false;
  Color? _customColor;
  String? _customFont;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeData get themeData => _themeData;
  bool get isDarkMode => _isDarkMode;
  Color? get customColor => _customColor;
  String? get customFont => _customFont;

  void toggleDarkMode(bool value) async {
    _isDarkMode = value;
    _themeData = value ? AppTheme.darkTheme : AppTheme.lightTheme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  void updateTheme(Color color, String font) {
    _customColor = color;
    _customFont = font;
    if (!_isDarkMode) {
      _themeData = AppTheme.fromColorAndFont(color, font);
      notifyListeners();
    }
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    _themeData = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    notifyListeners();
  }
}
