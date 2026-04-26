import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';

// NeuraApp Design System — Marka Renkleri
const Color kBackground = Color(0xFFF8F9FC);
const Color kPrimary = Color(0xFF0F766E);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF64748B);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // 🔥 timeout eklendi (takılmayı önler)
      await auth.checkSession().timeout(const Duration(seconds: 3));

      if (!mounted) return;

      if (auth.isLoggedIn) {
        if (auth.isPatient) {
          Navigator.pushReplacementNamed(context, '/patient-home');
        } else {
          Navigator.pushReplacementNamed(context, '/clinician-home');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              width: 220,
              height: 220,
            ),

            const SizedBox(height: 24),

            // "Neura" yazısı


            const SizedBox(height: 56),

            // Loading indicator
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: kPrimary,
                strokeWidth: 2.5,
                backgroundColor: kPrimary.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}