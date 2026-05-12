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
import 'package:app_links/app_links.dart';
import 'screens/reset_password.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await SupabaseService.init();
  runApp(const NeuraApp());
}

class NeuraApp extends StatefulWidget {
  const NeuraApp({super.key});
  @override
  State<NeuraApp> createState() => _NeuraAppState();
}

class _NeuraAppState extends State<NeuraApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    AppLinks().uriLinkStream.listen((uri) {
      if (uri.host == 'reset-password') {
        final accessToken = uri.queryParameters['access_token'];
        if (accessToken != null && accessToken.isNotEmpty) {
          _navigatorKey.currentState?.pushNamed(
            '/reset-password',
            arguments: {'access_token': accessToken},
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        navigatorKey: _navigatorKey,   // ← bunu ekledik
        title: 'Neura',
        debugShowCheckedModeBanner: false,
        theme: NeuraTheme.lightTheme,
        darkTheme: NeuraTheme.darkTheme,
        themeMode: ThemeMode.system,
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
          '/reset-password': (context) => const ResetPasswordScreen(),  // ← bunu ekledik
        },
        onGenerateInitialRoutes: (route) {
          print('=== INITIAL ROUTE: $route');
          if (route.contains('reset-password')) {
            final uri = Uri.parse('http://localhost:8080$route');
            final token = uri.queryParameters['token'];
            return [
              MaterialPageRoute(
                builder: (_) => const ResetPasswordScreen(),
                settings: RouteSettings(
                  name: '/reset-password',
                  arguments: token != null ? {'token': token} : null,
                ),
              ),
            ];
          }
          return [MaterialPageRoute(builder: (_) => const SplashScreen())];
        },
      ),
    );
  }
}