import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import '../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'clinician_1';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final nameParts = _fullNameController.text.trim().split(' ');
    final ad = nameParts.first;
    final soyad =
    nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final success = await auth.register(
      ad: ad,
      soyad: soyad,
      eposta: _emailController.text.trim(),
      telefon: '',
      sifre: _passwordController.text.trim(),
      rolAdi: 'Hasta',
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/patient-home');
    } else {
      _showErrorDialog(auth.errorMessage ?? 'BAĞLANTI_HATASI');
    }
  }

  void _showErrorDialog(String errorType) {
    String title;
    String message;

    if (errorType == 'EMAIL_KAYITLI') {
      title = 'GEÇERSİZ GİRİŞ';
      message =
      'Girdiğiniz bilgiler sistemimizle eşleşmiyor. Lütfen e-postanızı veya şifrenizi kontrol edin ve tekrar deneyin.';
    } else {
      title = 'BAĞLANTI HATASI';
      message =
      'Şu anda internete bağlı değilsiniz. Neura özelliklerini kullanmak için lütfen internet bağlantınızı kontrol edin.';
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
                child: const Text('Tekrar Dene'),
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
          icon: const Icon(Icons.arrow_back_ios, color: NeuraTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yeni Hesap',
          style: TextStyle(
            color: NeuraTheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tam Adınız',
                style: TextStyle(fontSize: 13, color: NeuraTheme.textGrey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  hintText: 'Ad Soyad',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: NeuraTheme.primary, size: 20),
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
                style: TextStyle(fontSize: 13, color: NeuraTheme.textGrey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: NeuraTheme.primary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: NeuraTheme.primary,
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

              const SizedBox(height: 16),

              const Text(
                'Email',
                style: TextStyle(fontSize: 13, color: NeuraTheme.textGrey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'ornek@email.com',
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: NeuraTheme.primary, size: 20),
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
                'Klinisyen Seç',
                style: TextStyle(fontSize: 13, color: NeuraTheme.textGrey),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'clinician_1',
                      child: Text('Dr. Ayşe Yılmaz'),
                    ),
                    DropdownMenuItem(
                      value: 'clinician_2',
                      child: Text('Dr. Mehmet Demir'),
                    ),
                    DropdownMenuItem(
                      value: 'clinician_3',
                      child: Text('Dr. Zeynep Kaya'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
              ),

              const SizedBox(height: 12),

              RichText(
                text: const TextSpan(
                  text: 'Devam ederek şunları kabul ediyorsunuz: ',
                  style:
                  TextStyle(color: NeuraTheme.textGrey, fontSize: 12),
                  children: [
                    TextSpan(
                      text: 'Kullanım Şartları',
                      style: TextStyle(
                          color: NeuraTheme.primary, fontSize: 12),
                    ),
                    TextSpan(text: ' ve '),
                    TextSpan(
                      text: 'Gizlilik Politikası',
                      style: TextStyle(
                          color: NeuraTheme.primary, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              CustomButton(
                text: 'Kayıt Ol',
                isLoading: auth.isLoading,
                onPressed: _register,
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: 'Zaten hesabın var mı? ',
                      style: TextStyle(color: NeuraTheme.textGrey),
                      children: [
                        TextSpan(
                          text: 'Giriş Yap',
                          style: TextStyle(
                            color: NeuraTheme.primary,
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