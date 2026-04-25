import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'patient';

  Color get _primaryColor => _selectedRole == 'patient'
      ? const Color(0xFF2260FF)
      : const Color(0xFF1DB954);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      if (auth.isPatient) {
        Navigator.pushReplacementNamed(context, '/patient-home');
      } else {
        Navigator.pushReplacementNamed(context, '/clinician-home');
      }
    } else {
      _showErrorDialog(auth.errorMessage ?? 'BAĞLANTI_HATASI');
    }
  }

  void _showErrorDialog(String errorType) {
    String title;
    String message;
    String buttonText;

    if (errorType == 'GEÇERSİZ_GİRİŞ') {
      title = 'GEÇERSİZ GİRİŞ';
      message =
      'Bu e-posta adresi/telefon numarasıyla daha önce bir hesap oluşturulmamış. Şifrenizi hatırlamıyorsanız, "Şifremi Unuttum" seçeneğine tıklayabilirsiniz.';
      buttonText = 'Tekrar Dene';
    } else {
      title = 'BAĞLANTI HATASI';
      message =
      'Şu anda internete bağlı değilsiniz. Neura özelliklerini kullanmak için lütfen internet bağlantınızı kontrol edin.';
      buttonText = 'Yenile';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: NeuraTheme.textGrey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Provider.of<AuthProvider>(context, listen: false)
                      .clearError();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeuraTheme.textDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: NeuraTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Logo
              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'N',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const TextSpan(
                        text: 'eura',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: NeuraTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'Sağlık Uygulaması',
                  style: TextStyle(
                    fontSize: 13,
                    color: NeuraTheme.textGrey,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                'Merhaba!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Neura'ya Hoşgeldin",
                style: TextStyle(
                  fontSize: 16,
                  color: NeuraTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Email veya Telefon Numarası',
                style: TextStyle(
                  fontSize: 13,
                  color: NeuraTheme.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email veya telefon numaranız',
                  hintStyle:
                  TextStyle(color: _primaryColor, fontSize: 13),
                  prefixIcon: Icon(Icons.email_outlined,
                      color: _primaryColor, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFEAF4FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Şifre',
                style: TextStyle(
                  fontSize: 13,
                  color: NeuraTheme.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••••••',
                  prefixIcon: Icon(Icons.lock_outline,
                      color: _primaryColor, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _primaryColor,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFFEAF4FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: Text(
                    'Şifremi unuttum?',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Rol Seçimi
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = 'patient'),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _selectedRole == 'patient'
                              ? const Color(0xFF2260FF)
                              : const Color(0xFFEAF4FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Hasta',
                            style: TextStyle(
                              color: _selectedRole == 'patient'
                                  ? Colors.white
                                  : NeuraTheme.textGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = 'clinician'),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _selectedRole == 'clinician'
                              ? const Color(0xFF1DB954)
                              : const Color(0xFFEAF4FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Klinisyen',
                            style: TextStyle(
                              color: _selectedRole == 'clinician'
                                  ? Colors.white
                                  : NeuraTheme.textGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: auth.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Giriş Yap',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {
                    if (_selectedRole == 'clinician') {
                      Navigator.pushNamed(context, '/register-clinician');
                    } else {
                      Navigator.pushNamed(context, '/register');
                    }
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Hesabınız yok mu? ",
                      style: const TextStyle(color: NeuraTheme.textGrey),
                      children: [
                        TextSpan(
                          text: 'Kayıt Ol',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
