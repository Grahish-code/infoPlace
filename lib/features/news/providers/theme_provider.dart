import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeIndex = prefs.getInt(_themeKey) ?? 0;

    switch (savedThemeIndex) {
      case 0:
        _themeMode = ThemeMode.system;
        break;
      case 1:
        _themeMode = ThemeMode.light;
        break;
      case 2:
        _themeMode = ThemeMode.dark;
        break;
    }

    _updateDarkModeStatus();
    notifyListeners();
  }

  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    int themeIndex;

    switch (_themeMode) {
      case ThemeMode.system:
        themeIndex = 0;
        break;
      case ThemeMode.light:
        themeIndex = 1;
        break;
      case ThemeMode.dark:
        themeIndex = 2;
        break;
    }

    await prefs.setInt(_themeKey, themeIndex);
  }

  void _updateDarkModeStatus() {
    if (_themeMode == ThemeMode.system) {
      _isDarkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    } else {
      _isDarkMode = _themeMode == ThemeMode.dark;
    }

    // Update system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: _isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
        systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
    }

    _updateDarkModeStatus();
    _saveThemeMode();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _updateDarkModeStatus();
      _saveThemeMode();
      notifyListeners();
    }
  }

  // Call this method when system brightness changes
  void updateSystemBrightness() {
    if (_themeMode == ThemeMode.system) {
      final wasSystemDark = _isDarkMode;
      _updateDarkModeStatus();

      if (wasSystemDark != _isDarkMode) {
        notifyListeners();
      }
    }
  }

  // Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF2196F3),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2196F3),
        secondary: Color(0xFF21CBF3),
        surface: Colors.white,
        background: Color(0xFFF8F9FA),
        error: Color(0xFFE53E3E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        onError: Colors.white,
      ),
    );
  }

  // Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF2196F3),
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Colors.white70,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2196F3),
        secondary: Color(0xFF21CBF3),
        surface: Color(0xFF1A1A1A),
        background: Color(0xFF0A0A0A),
        error: Color(0xFFE53E3E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
      ),
    );
  }
}