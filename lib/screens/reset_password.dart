import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String _accessToken = '';

  static const String _baseUrl = 'https://griteunvazwekosffmjo.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kTextDark = Color(0xFF1E293B);
  static const Color kTextGrey = Color(0xFF64748B);
  static const Color kInputFill = Color(0xFFF1F5F9);
  static const Color kPrimary = Color(0xFF2563EB);

  @override
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Mobil deep link
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args['access_token'] != null) {
      _accessToken = args['access_token'];
      return;
    }

    // Web — URL'den token oku
    final uri = Uri.base;
    final token = uri.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      _verifyToken(token);
    }
  }

  Future<void> _verifyToken(String token) async {
    // Önce token ile OTP verify et
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/v1/verify'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': _anonKey,
      },
      body: jsonEncode({
        'token_hash': token,
        'type': 'recovery',
      }),
    );

    print('=== VERIFY STATUS: ${response.statusCode}');
    print('=== VERIFY BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _accessToken = data['access_token'] ?? '';
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link geçersiz veya süresi dolmuş.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre en az 8 karakter olmalı')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreler uyuşmuyor')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await http.put(
      Uri.parse('$_baseUrl/auth/v1/user'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': _anonKey,
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({'password': password}),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreniz başarıyla güncellendi!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hata oluştu. Link süresi dolmuş olabilir.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kTextDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Yeni Şifre Belirle',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: kTextDark)),
              const SizedBox(height: 8),
              const Text(
                'Lütfen yeni şifrenizi girin.',
                style: TextStyle(color: kTextGrey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              const Text('Yeni Şifre',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextDark)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscure1,
                decoration: InputDecoration(
                  hintText: 'Yeni şifreniz',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: kPrimary, size: 20,
                    ),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                  filled: true,
                  fillColor: kInputFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: kPrimary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Şifre Tekrar',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextDark)),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmController,
                obscureText: _obscure2,
                decoration: InputDecoration(
                  hintText: 'Şifrenizi tekrar girin',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: kPrimary, size: 20,
                    ),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                  filled: true,
                  fillColor: kInputFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: kPrimary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                      : const Text('Şifremi Güncelle',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}