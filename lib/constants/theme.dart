import 'package:flutter/material.dart';

class AppColors {
  static const Color blue1 = Color.fromARGB(255, 42, 162, 214); // RGBA: 42, 162, 214, 255
  static const Color blue2 = Color.fromARGB(255, 94, 186, 226); // RGBA: 94, 186, 226, 255
  static const Color blue3 = Color.fromARGB(255, 145, 207, 234); // RGBA: 145, 207, 234, 255
  static const Color white = Color.fromARGB(255, 255, 255, 255); // RGBA: 255, 255, 255, 255
  static const Color dark = Color.fromARGB(255, 17, 20, 24);  // RGBA: 17, 20, 24, 255
  static const Color success = Color.fromARGB(255, 145, 234, 145); // RGBA: 145, 207, 234, 255
  static const Color danger = Color.fromARGB(255, 233, 124, 124); // RGBA: 255, 0, 0, 255
  static const Color warning = Color.fromARGB(255, 230, 189, 113); // RGBA: 255, 165, 0, 255
}

final ThemeData drinkUpTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.dark,
  colorScheme: const ColorScheme.dark().copyWith(
    primary: AppColors.blue2,
    onPrimary: AppColors.white,
    secondary: AppColors.blue3,
    onSecondary: AppColors.dark,
    error: AppColors.danger,  // Using error instead of danger
    onError: AppColors.white,
    surface: AppColors.dark,
    onSurface: AppColors.white,
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(color: AppColors.white),
    bodyMedium: TextStyle(color: AppColors.white),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.blue2,
    foregroundColor: AppColors.white,
  ),
);
