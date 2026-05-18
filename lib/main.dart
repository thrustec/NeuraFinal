import 'dart:async';
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

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
          (uri) {
        _handleIncomingResetLink(uri);
      },
      onError: (error) {
        debugPrint('Deep link hatası: $error');
      },
    );
  }

  bool _isResetPasswordUri(Uri uri) {
    return uri.host == 'reset-password' ||
        uri.path.contains('reset-password');
  }

  Map<String, String> _extractAllParams(Uri uri) {
    final params = <String, String>{};

    // ?access_token=... veya ?code=...
    params.addAll(uri.queryParameters);

    // #access_token=...&refresh_token=...
    if (uri.fragment.isNotEmpty) {
      try {
        params.addAll(Uri.splitQueryString(uri.fragment));
      } catch (e) {
        debugPrint('Fragment parse hatası: $e');
      }
    }

    return params;
  }

  Map<String, String> _buildResetArguments(Uri uri) {
    final params = _extractAllParams(uri);

    final args = <String, String>{};

    final accessToken = params['access_token'];
    final refreshToken = params['refresh_token'];
    final code = params['code'];
    final token = params['token'];
    final tokenHash = params['token_hash'];
    final type = params['type'];

    if (accessToken != null && accessToken.isNotEmpty) {
      args['access_token'] = accessToken;
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      args['refresh_token'] = refreshToken;
    }

    if (code != null && code.isNotEmpty) {
      args['code'] = code;
    }

    if (token != null && token.isNotEmpty) {
      args['token'] = token;
    }

    if (tokenHash != null && tokenHash.isNotEmpty) {
      args['token_hash'] = tokenHash;
    }

    if (type != null && type.isNotEmpty) {
      args['type'] = type;
    }

    return args;
  }

  void _handleIncomingResetLink(Uri uri) {
    if (!_isResetPasswordUri(uri)) return;

    final arguments = _buildResetArguments(uri);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushNamed(
        '/reset-password',
        arguments: arguments,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Neura',
        debugShowCheckedModeBanner: false,
        theme: NeuraTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/register-clinician': (context) =>
          const RegisterClinicianScreen(),
          '/clinician-agenda': (context) => const ClinicianAgenda(),
          '/patient-home': (context) =>
          const MainScreen(isClinician: false),
          '/clinician-home': (context) =>
          const MainScreen(isClinician: true),
          '/reset-password': (context) => const ResetPasswordScreen(),
        },

        // Web'de kullanıcı reset linkini doğrudan tarayıcıda açarsa
        // ilk route üzerinden token bilgilerini yakalıyoruz.
        onGenerateInitialRoutes: (route) {
          final initialUri = Uri.base;

          if (route.contains('reset-password') ||
              initialUri.path.contains('reset-password')) {
            final arguments = _buildResetArguments(initialUri);

            return [
              MaterialPageRoute(
                builder: (_) => const ResetPasswordScreen(),
                settings: RouteSettings(
                  name: '/reset-password',
                  arguments: arguments,
                ),
              ),
            ];
          }

          return [
            MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            ),
          ];
        },
      ),
    );
  }
}