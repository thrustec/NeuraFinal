import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isPatient => _user?.isPatient ?? false;
  bool get isClinician => _user?.isClinician ?? false;

  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      final userMap = jsonDecode(userJson);
      _user = UserModel.fromJson(userMap);
      notifyListeners();
    }
  }

  Future<bool> login(String eposta, String sifre) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(eposta, sifre);
      await _saveSession(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e.toString().contains('GEÇERSİZ_GİRİŞ')) {
        _errorMessage = 'GEÇERSİZ_GİRİŞ';
      } else {
        _errorMessage = 'BAĞLANTI_HATASI';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String ad,
    required String soyad,
    required String eposta,
    required String sifre,
    required String rolAdi,
    String? unvan,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        ad: ad, soyad: soyad, eposta: eposta,
        sifre: sifre, rolAdi: rolAdi, unvan: unvan,
      );
      await _saveSession(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e.toString().contains('EMAIL_KAYITLI')) {
        _errorMessage = 'EMAIL_KAYITLI';
      } else {
        _errorMessage = 'BAĞLANTI_HATASI';
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Profil Güncelleme ────────────────────────────────────
  Future<bool> updateUser({
    String? ad,
    String? soyad,
    String? unvan,
  }) async {
    if (_user == null) return false;

    try {
      final yeniAd    = ad    ?? _user!.ad;
      final yeniSoyad = soyad ?? _user!.soyad;
      final yeniUnvan = unvan ?? _user!.unvan;

      await Supabase.instance.client
          .schema('neura')
          .from('kullanicilar')
          .update({'ad': yeniAd, 'soyad': yeniSoyad})
          .eq('kullaniciId', int.parse(_user!.id));

      _user = UserModel(
        id:        _user!.id,
        ad:        yeniAd,
        soyad:     yeniSoyad,
        eposta:    _user!.eposta,
        rolId:     _user!.rolId,
        rolAdi:    _user!.rolAdi,
        token:     _user!.token,
        unvan:     yeniUnvan,
        avatarUrl: _user!.avatarUrl,
      );

      await _saveSession(_user!);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Avatar Yükleme ───────────────────────────────────────

  Future<bool> updateAvatar(Uint8List bytes) async {
    if (_user == null) return false;

    try {
      // Token'ı set et
      if (_user!.token.isNotEmpty) {
        await Supabase.instance.client.auth.setSession(_user!.token);
      }

      final dosyaYolu = '${_user!.id}.jpg';
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
        dosyaYolu,
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      final url = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(dosyaYolu);

      await Supabase.instance.client
          .schema('neura')
          .from('kullanicilar')
          .update({'avatarUrl': url})
          .eq('kullaniciId', int.parse(_user!.id));

      _user = UserModel(
        id:        _user!.id,
        ad:        _user!.ad,
        soyad:     _user!.soyad,
        eposta:    _user!.eposta,
        rolId:     _user!.rolId,
        rolAdi:    _user!.rolAdi,
        token:     _user!.token,
        unvan:     _user!.unvan,
        avatarUrl: url,
      );

      await _saveSession(_user!);
      notifyListeners();
      return true;
    } catch (e) {
      print('AVATAR HATA: $e');
      return false;
    }
  }

  // ── E-posta Güncelleme ───────────────────────────────────
  Future<bool> updateEposta({required String yeniEposta}) async {
    if (_user == null) return false;

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(email: yeniEposta),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Şifre Güncelleme ─────────────────────────────────────
  Future<bool> updateSifre({
    required String mevcutSifre,
    required String yeniSifre,
  }) async {
    if (_user == null) return false;

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email:    _user!.eposta,
        password: mevcutSifre,
      );
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: yeniSifre),
      );
      await Supabase.instance.client
          .schema('neura')
          .from('kullanicilar')
          .update({'sifreHash': yeniSifre})
          .eq('kullaniciId', int.parse(_user!.id));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}