import 'package:flutter/material.dart';

class AppColors {
  static const Color blue1 = Color.fromARGB(255, 42, 162, 214); // RGBA: 42, 162, 214, 255
  static const Color blue2 = Color.fromARGB(255, 94, 186, 226); // RGBA: 94, 186, 226, 255
  static const Color blue3 = Color.fromARGB(255, 145, 207, 234); // RGBA: 145, 207, 234, 255
  static const Color white = Color.fromARGB(255, 255, 255, 255); // RGBA: 255, 255, 255, 255
  static const Color dark = Color.fromARGB(255, 17, 20, 24);  // RGBA: 17, 20, 24, 255
}

final ThemeData drinkUpTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.white,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.blue2,
    onPrimary: AppColors.white,
    secondary: AppColors.blue3,
    onSecondary: AppColors.dark,
    background: AppColors.white,
    onBackground: AppColors.dark,
    surface: AppColors.blue1,
    onSurface: AppColors.white,
    error: Colors.red,
    onError: AppColors.white,
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(color: AppColors.dark),
    bodyMedium: TextStyle(color: AppColors.dark),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.blue2,
    foregroundColor: AppColors.white,
  ),
);
