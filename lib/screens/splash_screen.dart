import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';

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
      backgroundColor: NeuraTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'N',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: NeuraTheme.primary,
                    ),
                  ),
                  TextSpan(
                    text: 'eura',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: NeuraTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sağlık Uygulaması',
              style: TextStyle(
                fontSize: 16,
                color: NeuraTheme.textGrey,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: NeuraTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}