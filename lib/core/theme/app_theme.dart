import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF155EEF);
  static const Color darkBlue = Color(0xFF06235F);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: Colors.white,

    colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,

        minimumSize: const Size(double.infinity, 52),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
