import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
      ? const Color(0xFF2563EB)
      : const Color(0xFF0F766E);

  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kTextDark = Color(0xFF1E293B);
  static const Color kTextGrey = Color(0xFF64748B);
  static const Color kInputFill = Color(0xFFF1F5F9);

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
      final gercekRol = auth.isPatient ? 'patient' : 'clinician';
      if (gercekRol != _selectedRole) {
        await auth.logout();
        _showErrorDialog('ROL_UYUSMUYOR');
        return;
      }

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

    if (errorType == 'ROL_UYUSMUYOR') {
      title = 'GEÇERSİZ GİRİŞ';
      message = 'Girdiğiniz bilgilere ait bir kayıt bulunmamaktadır.';
      buttonText = 'Tekrar Dene';
    } else if (errorType == 'GEÇERSİZ_GİRİŞ') {
      title = 'GEÇERSİZ GİRİŞ';
      message = 'Bu e-posta adresiyle eşleşen bir hesap bulunamadı. Şifrenizi hatırlamıyorsanız, "Şifremi Unuttum" seçeneğine tıklayabilirsiniz.';
      buttonText = 'Tekrar Dene';
    } else {
      title = 'BAĞLANTI HATASI';
      message = 'Şu anda internete bağlı değilsiniz. Neura özelliklerini kullanmak için lütfen internet bağlantınızı kontrol edin.';
      buttonText = 'Yenile';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kTextDark),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextGrey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Provider.of<AuthProvider>(context, listen: false).clearError();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // LOGO
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text('Akıllı Sağlık Asistanı', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500, letterSpacing: 0.5)),
              ),

              const SizedBox(height: 50),

              Text('Merhaba!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _primaryColor)),
              const SizedBox(height: 6),
              const Text("Neura'ya Hoşgeldin", style: TextStyle(fontSize: 16, color: kTextDark, fontWeight: FontWeight.w600)),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0).withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'patient'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 48,
                          decoration: BoxDecoration(
                            color: _selectedRole == 'patient' ? _primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedRole == 'patient' ? [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                          ),
                          child: Center(
                            child: Text(
                              'Hasta',
                              style: TextStyle(color: _selectedRole == 'patient' ? Colors.white : kTextGrey, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'clinician'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 48,
                          decoration: BoxDecoration(
                            color: _selectedRole == 'clinician' ? _primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedRole == 'clinician' ? [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                          ),
                          child: Center(
                            child: Text(
                              'Klinisyen',
                              style: TextStyle(color: _selectedRole == 'clinician' ? Colors.white : kTextGrey, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text('E-posta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextGrey)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 15, color: kTextDark),
                decoration: InputDecoration(
                  hintText: 'ornek@email.com',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: Icon(Icons.email_outlined, color: _primaryColor, size: 22),
                  filled: true,
                  fillColor: kInputFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                ),
              ),

              const SizedBox(height: 20),

              const Text('Şifre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextGrey)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 15, color: kTextDark),
                decoration: InputDecoration(
                  hintText: '••••••••••••',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: Icon(Icons.lock_outline, color: _primaryColor, size: 22),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _primaryColor, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: kInputFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // DÜZELTME BURADA: _selectedRole'ü arguments olarak iletiyoruz
                    Navigator.pushNamed(
                      context,
                      '/forgot-password',
                      arguments: _selectedRole,
                    );
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('Şifremi unuttum', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Giriş Yap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                ),
              ),

              const SizedBox(height: 24),

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
                      style: const TextStyle(color: kTextGrey, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Kayıt Ol',
                          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
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