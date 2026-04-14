import 'package:flutter/material.dart';
import 'screens/patient_list_screen.dart';

void main() {
  runApp(const NeuraApp());
}

class NeuraApp extends StatelessWidget {
  const NeuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuraApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
        ),
        useMaterial3: true,
      ),
      home: const PatientListScreen(),
    );
  }
}