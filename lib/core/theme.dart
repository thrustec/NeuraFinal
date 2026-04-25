import 'package:flutter/material.dart';

class NeuraTheme {
  static const Color primary = Color(0xFF2260FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF94A3B8);

  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    useMaterial3: true,
    scaffoldBackgroundColor: background,
  );
}
