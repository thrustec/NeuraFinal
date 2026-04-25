import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/clinician_agenda.dart';
import 'screens/forget_password.dart';
import 'screens/register_clinician_screen.dart';
import 'services/supabase_service.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const NeuraApp());
}

class NeuraApp extends StatelessWidget {
  const NeuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Neura',
        debugShowCheckedModeBanner: false,
        theme: NeuraTheme.theme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/register-clinician': (context) => const RegisterClinicianScreen(),
          '/clinician-agenda': (context) => const ClinicianAgenda(),
          '/patient-home': (context) => const MainScreen(isClinician: false),
          '/clinician-home': (context) => const MainScreen(isClinician: true),
        },
      ),
    );
  }
}