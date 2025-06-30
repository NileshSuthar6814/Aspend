import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 16),
      titleLarge: TextStyle(fontWeight: FontWeight.bold),
    ),
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.tealAccent, brightness: Brightness.dark),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 16),
      titleLarge: TextStyle(fontWeight: FontWeight.bold),
    ),
    useMaterial3: true,
  );
}
