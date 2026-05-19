import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  StreamSubscription<AuthState>? _authSubscription;
  Timer? _recoveryTimeoutTimer;

  bool _isLoading = false;
  bool _isPreparingRecovery = true;
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _initialized = false;

  String? _recoveryError;

  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kTextDark = Color(0xFF1E293B);
  static const Color kTextGrey = Color(0xFF64748B);
  static const Color kInputFill = Color(0xFFF1F5F9);
  static const Color kPrimary = Color(0xFF2563EB);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    _prepareRecoverySession();
  }

  Future<void> _prepareRecoverySession() async {
    try {
      final currentSession = SupabaseService.client.auth.currentSession;

      // Supabase recovery linkini işlediyse session zaten hazırdır.
      if (currentSession != null) {
        _markRecoveryReady();
        return;
      }

      // Session hemen hazır değilse passwordRecovery event'ini dinle.
      _authSubscription =
          SupabaseService.client.auth.onAuthStateChange.listen(
                (data) {
              final event = data.event;
              final session = data.session;

              if (event == AuthChangeEvent.passwordRecovery &&
                  session != null) {
                _markRecoveryReady();
              }
            },
            onError: (error, stackTrace) {
              _markRecoveryError(
                'Şifre sıfırlama bağlantısı doğrulanamadı.',
              );
            },
          );

      // Güvenlik: Event gelmezse sonsuza kadar yükleniyor kalmasın.
      _recoveryTimeoutTimer = Timer(const Duration(seconds: 8), () {
        if (_isPreparingRecovery) {
          _markRecoveryError(
            'Şifre sıfırlama oturumu başlatılamadı. Lütfen yeni bir bağlantı isteyin.',
          );
        }
      });
    } catch (_) {
      _markRecoveryError(
        'Şifre sıfırlama bağlantısı işlenirken hata oluştu.',
      );
    }
  }

  void _markRecoveryReady() {
    if (!mounted) return;

    _recoveryTimeoutTimer?.cancel();

    setState(() {
      _isPreparingRecovery = false;
      _recoveryError = null;
    });
  }

  void _markRecoveryError(String message) {
    if (!mounted) return;

    _recoveryTimeoutTimer?.cancel();

    setState(() {
      _isPreparingRecovery = false;
      _recoveryError = message;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _authSubscription?.cancel();
    _recoveryTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (_recoveryError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_recoveryError!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre en az 8 karakter olmalı'),
        ),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreler uyuşmuyor'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(
          password: password,
        ),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreniz başarıyla güncellendi!'),
          backgroundColor: Colors.green,
        ),
      );

      await SupabaseService.client.auth.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (_) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Şifre güncellenemedi: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre güncellenirken hata oluştu.'),
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: kTextDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: _isPreparingRecovery
              ? _buildLoadingState()
              : _recoveryError != null
              ? _buildErrorState()
              : _buildPasswordForm(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 420,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: kPrimary,
            ),
            SizedBox(height: 18),
            Text(
              'Bağlantı doğrulanıyor...',
              style: TextStyle(
                color: kTextGrey,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 420,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.link_off_rounded,
              color: Colors.red,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bağlantı Kullanılamıyor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _recoveryError ??
                  'Şifre sıfırlama bağlantısı geçersiz olabilir.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextGrey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                        (_) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Giriş Ekranına Dön',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yeni Şifre Belirle',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Lütfen yeni şifrenizi girin.',
          style: TextStyle(
            color: kTextGrey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),

        const Text(
          'Yeni Şifre',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscure1,
          decoration: InputDecoration(
            hintText: 'Yeni şifreniz',
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
            ),
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure1
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: kPrimary,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscure1 = !_obscure1;
                });
              },
            ),
            filled: true,
            fillColor: kInputFill,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: kPrimary,
                width: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Şifre Tekrar',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmController,
          obscureText: _obscure2,
          decoration: InputDecoration(
            hintText: 'Şifrenizi tekrar girin',
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
            ),
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure2
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: kPrimary,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscure2 = !_obscure2;
                });
              },
            ),
            filled: true,
            fillColor: kInputFill,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: kPrimary,
                width: 1.5,
              ),
            ),
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
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : const Text(
              'Şifremi Güncelle',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}