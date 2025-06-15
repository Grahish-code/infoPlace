import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      background: AppColors.background,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 18),
    ),
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: ColorScheme.dark(
      primary: AppColors.darkPrimary,
      background: AppColors.darkBackground,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 18),
    ),
    useMaterial3: true,
  );
}
