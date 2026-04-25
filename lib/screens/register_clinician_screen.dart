import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';

class RegisterClinicianScreen extends StatefulWidget {
  const RegisterClinicianScreen({super.key});

  @override
  State<RegisterClinicianScreen> createState() =>
      _RegisterClinicianScreenState();
}

class _RegisterClinicianScreenState extends State<RegisterClinicianScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  static const Color _green = Color(0xFF1DB954);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  Future<void> _register() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final passwordConfirm = _passwordConfirmController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        passwordConfirm.isEmpty) {
      _showValidationError('Lütfen tüm alanları doldurun');
      return;
    }

    if (!_isValidEmail(email)) {
      _showValidationError(
          'Geçerli bir e-posta adresi girin\nÖrnek: ornek@mail.com');
      return;
    }

    if (!_isValidPassword(password)) {
      _showValidationError(
          'Şifre en az 8 karakter olmalı ve\nbüyük harf, küçük harf ile\nrakam veya özel karakter içermelidir');
      return;
    }

    if (password != passwordConfirm) {
      _showValidationError('Şifreler uyuşmuyor');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final nameParts = fullName.split(' ');
    final ad = nameParts.first;
    final soyad =
    nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final success = await auth.register(
      ad: ad,
      soyad: soyad,
      eposta: email,
      telefon: '',
      sifre: password,
      rolAdi: 'Klinisyen',
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/clinician-home');
    } else {
      _showErrorDialog(auth.errorMessage ?? 'BAĞLANTI_HATASI');
    }
  }

  void _showValidationError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Geçersiz Bilgi',
              style:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: NeuraTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeuraTheme.textDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tamam'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String errorType) {
    String title;
    String message;

    if (errorType == 'EMAIL_KAYITLI') {
      title = 'E-posta Kayıtlı';
      message =
      'Bu e-posta adresi zaten kayıtlı. Lütfen giriş yapın.';
    } else {
      title = 'Bağlantı Hatası';
      message =
      'Şu anda internete bağlı değilsiniz. Lütfen bağlantınızı kontrol edin.';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: NeuraTheme.textGrey, fontSize: 13)),
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
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tamam'),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yeni Hesap',
          style: TextStyle(color: _green, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tam Adı
              const Text('Tam Adınız',
                  style: TextStyle(
                      fontSize: 13, color: NeuraTheme.textGrey)),
              const SizedBox(height: 8),
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  hintText: 'Ad Soyad',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: _green, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFEAF4FB),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 16),

              // Email
              const Text('Email',
                  style: TextStyle(
                      fontSize: 13, color: NeuraTheme.textGrey)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'ornek@email.com',
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: _green, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFEAF4FB),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 16),

              // Şifre
              const Text('Şifre',
                  style: TextStyle(
                      fontSize: 13, color: NeuraTheme.textGrey)),
              const SizedBox(height: 4),
              const Text(
                'En az 8 karakter, büyük/küçük harf ve rakam içermeli',
                style:
                TextStyle(fontSize: 11, color: NeuraTheme.textGrey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: _green, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _green,
                      size: 20,
                    ),
                    onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFEAF4FB),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 16),

              // Şifre Tekrar
              const Text('Şifre Tekrar',
                  style: TextStyle(
                      fontSize: 13, color: NeuraTheme.textGrey)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordConfirmController,
                obscureText: _obscurePasswordConfirm,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: _green, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePasswordConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _green,
                      size: 20,
                    ),
                    onPressed: () => setState(() =>
                    _obscurePasswordConfirm =
                    !_obscurePasswordConfirm),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFEAF4FB),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 12),

              RichText(
                text: const TextSpan(
                  text: 'Devam ederek şunları kabul ediyorsunuz: ',
                  style: TextStyle(
                      color: NeuraTheme.textGrey, fontSize: 12),
                  children: [
                    TextSpan(
                        text: 'Kullanım Şartları',
                        style:
                        TextStyle(color: _green, fontSize: 12)),
                    TextSpan(text: ' ve '),
                    TextSpan(
                        text: 'Gizlilik Politikası',
                        style:
                        TextStyle(color: _green, fontSize: 12)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: auth.isLoading
                      ? const CircularProgressIndicator(
                      color: Colors.white)
                      : const Text(
                    'Kayıt Ol',
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
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Zaten hesabın var mı? ',
                      style: TextStyle(color: NeuraTheme.textGrey),
                      children: [
                        TextSpan(
                          text: 'Giriş Yap',
                          style: TextStyle(
                              color: _green,
                              fontWeight: FontWeight.w600),
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