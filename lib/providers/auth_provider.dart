import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// ── Supabase sabitleri ────────────────────────────────────────────────────────
const _kSupabaseUrl = 'https://griteunvazwekosffmjo.supabase.co';
const _kAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0'
    '.q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

Map<String, String> _neuraHeaders(String token) => {
  'apikey':          _kAnonKey,
  'Authorization':   'Bearer $token',
  'Content-Type':    'application/json',
  'Accept-Profile':  'neura',
  'Content-Profile': 'neura',
};

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
  // kullanicilar.kullaniciId — used for degerlendirmeler.klinisyenId writes/queries
  int get kullaniciId => int.tryParse(_user?.id ?? '') ?? 0;

  // ── Session Kontrolü ─────────────────────────────────────
  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      final userMap = jsonDecode(userJson);
      _user = UserModel.fromJson(userMap);
      notifyListeners();
    }
  }

  // ── Giriş Yap ────────────────────────────────────────────
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
      _errorMessage = e.toString().contains('GEÇERSİZ_GİRİŞ')
          ? 'GEÇERSİZ_GİRİŞ'
          : 'BAĞLANTI_HATASI';
      notifyListeners();
      return false;
    }
  }

  // ── Kayıt Ol ─────────────────────────────────────────────
  Future<bool> register({
    required String ad,
    required String soyad,
    required String eposta,
    required String sifre,
    required String rolAdi,
    String? unvan,
    int? klinisyenId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        ad: ad,
        soyad: soyad,
        eposta: eposta,
        sifre: sifre,
        rolAdi: rolAdi,
        unvan: unvan,
        klinisyenId: klinisyenId,
      );
      await _saveSession(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().contains('EMAIL_KAYITLI')
          ? 'EMAIL_KAYITLI'
          : 'BAĞLANTI_HATASI';
      notifyListeners();
      return false;
    }
  }

  // ── Çıkış Yap ────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Profil Güncelleme (ad / soyad / unvan) ───────────────
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

      final res = await http.patch(
        Uri.parse('$_kSupabaseUrl/rest/v1/kullanicilar?kullaniciId=eq.${_user!.id}'),
        headers: _neuraHeaders(_user!.token),
        body: jsonEncode({'ad': yeniAd, 'soyad': yeniSoyad}),
      );

      if (res.statusCode != 200 && res.statusCode != 204 && res.statusCode != 201) {
        debugPrint('updateUser HATA: ${res.statusCode} ${res.body}');
        return false;
      }

      _user = UserModel(
        id:          _user!.id,
        ad:          yeniAd,
        soyad:       yeniSoyad,
        eposta:      _user!.eposta,
        rolId:       _user!.rolId,
        rolAdi:      _user!.rolAdi,
        token:       _user!.token,
        unvan:       yeniUnvan,
        avatarUrl:   _user!.avatarUrl,
        klinisyenId: _user!.klinisyenId,
      );
      await _saveSession(_user!);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('updateUser HATA: $e');
      return false;
    }
  }

  // ── Avatar Yükleme ───────────────────────────────────────
  // HTTP PUT — Supabase SDK session gerekmez.
  Future<bool> updateAvatar(Uint8List bytes) async {
    if (_user == null) return false;
    try {
      final token     = _user!.token;
      final dosyaYolu = '${_user!.id}.jpg';
      const bucket    = 'avatars';

      // 1) Storage'a yükle
      final uploadRes = await http.put(
        Uri.parse('$_kSupabaseUrl/storage/v1/object/$bucket/$dosyaYolu'),
        headers: {
          'apikey':        _kAnonKey,
          'Authorization': 'Bearer $token',
          'Content-Type':  'image/jpeg',
          'x-upsert':      'true',
        },
        body: bytes,
      );

      if (uploadRes.statusCode != 200 && uploadRes.statusCode != 201) {
        debugPrint('AVATAR STORAGE HATA: ${uploadRes.statusCode} ${uploadRes.body}');
        return false;
      }

      final publicUrl =
          '$_kSupabaseUrl/storage/v1/object/public/$bucket/$dosyaYolu';

      // 2) DB güncelle
      final patchRes = await http.patch(
        Uri.parse('$_kSupabaseUrl/rest/v1/kullanicilar?kullaniciId=eq.${_user!.id}'),
        headers: _neuraHeaders(token),
        body: jsonEncode({'avatarUrl': publicUrl}),
      );

      if (patchRes.statusCode != 200 && patchRes.statusCode != 204 && patchRes.statusCode != 201) {
        debugPrint('AVATAR DB HATA: ${patchRes.statusCode} ${patchRes.body}');
        return false;
      }

      _user = UserModel(
        id:          _user!.id,
        ad:          _user!.ad,
        soyad:       _user!.soyad,
        eposta:      _user!.eposta,
        rolId:       _user!.rolId,
        rolAdi:      _user!.rolAdi,
        token:       _user!.token,
        unvan:       _user!.unvan,
        avatarUrl:   publicUrl,
        klinisyenId: _user!.klinisyenId,
      );
      await _saveSession(_user!);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AVATAR HATA: $e');
      return false;
    }
  }

  // ── E-posta Güncelleme ───────────────────────────────────
  //
  // DÜZELTME: Hem Supabase Auth (/auth/v1/user PUT) hem de
  // neura.kullanicilar.eposta güncelleniyor.
  // Böylece kullanıcı yeni e-postasıyla giriş yapabilir.
  //
  Future<bool> updateEposta({required String yeniEposta}) async {
    if (_user == null) return false;
    try {
      final token = _user!.token;

      // 1) Supabase Auth e-postasını güncelle (access_token yeterli)
      final authRes = await http.put(
        Uri.parse('$_kSupabaseUrl/auth/v1/user'),
        headers: {
          'apikey':        _kAnonKey,
          'Authorization': 'Bearer $token',
          'Content-Type':  'application/json',
        },
        body: jsonEncode({'email': yeniEposta}),
      );

      if (authRes.statusCode != 200) {
        debugPrint('Auth e-posta HATA: ${authRes.statusCode} ${authRes.body}');
        // Auth başarısız olsa bile DB'yi güncelle (best-effort)
      }

      // 2) neura.kullanicilar.eposta güncelle
      final dbRes = await http.patch(
        Uri.parse('$_kSupabaseUrl/rest/v1/kullanicilar?kullaniciId=eq.${_user!.id}'),
        headers: _neuraHeaders(token),
        body: jsonEncode({'eposta': yeniEposta}),
      );

      if (dbRes.statusCode != 200 && dbRes.statusCode != 204 && dbRes.statusCode != 201) {
        debugPrint('E-POSTA DB HATA: ${dbRes.statusCode} ${dbRes.body}');
        return false;
      }

      // 3) Yerel model güncelle
      _user = UserModel(
        id:          _user!.id,
        ad:          _user!.ad,
        soyad:       _user!.soyad,
        eposta:      yeniEposta,
        rolId:       _user!.rolId,
        rolAdi:      _user!.rolAdi,
        token:       _user!.token,
        unvan:       _user!.unvan,
        avatarUrl:   _user!.avatarUrl,
        klinisyenId: _user!.klinisyenId,
      );
      await _saveSession(_user!);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('E-posta güncelleme hatası: $e');
      return false;
    }
  }

  // ── Şifre Güncelleme ─────────────────────────────────────
  //
  // DÜZELTME: Mevcut şifreyle token alınır (doğrulama),
  // sonra /auth/v1/user PUT ile yeni şifre yazılır.
  // Kullanıcı yeni şifresiyle giriş yapabilir.
  //
  Future<bool> updateSifre({
    required String mevcutSifre,
    required String yeniSifre,
  }) async {
    if (_user == null) return false;
    try {
      // 1) Mevcut şifreyle doğrulama token al
      final tokenRes = await http.post(
        Uri.parse('$_kSupabaseUrl/auth/v1/token?grant_type=password'),
        headers: {
          'apikey':        _kAnonKey,
          'Authorization': 'Bearer $_kAnonKey',
          'Content-Type':  'application/json',
        },
        body: jsonEncode({
          'email':    _user!.eposta,
          'password': mevcutSifre,
        }),
      );

      if (tokenRes.statusCode != 200) {
        debugPrint('Mevcut şifre yanlış: ${tokenRes.statusCode}');
        return false; // Mevcut şifre hatalı
      }

      final tokenData = jsonDecode(tokenRes.body) as Map<String, dynamic>;
      final freshToken = tokenData['access_token'] as String? ?? _user!.token;

      // 2) Supabase Auth — yeni şifreyi güncelle
      final authRes = await http.put(
        Uri.parse('$_kSupabaseUrl/auth/v1/user'),
        headers: {
          'apikey':        _kAnonKey,
          'Authorization': 'Bearer $freshToken',
          'Content-Type':  'application/json',
        },
        body: jsonEncode({'password': yeniSifre}),
      );

      if (authRes.statusCode != 200) {
        debugPrint('Auth şifre HATA: ${authRes.statusCode} ${authRes.body}');
        return false;
      }

      // 3) neura.kullanicilar.sifreHash güncelle
      await http.patch(
        Uri.parse('$_kSupabaseUrl/rest/v1/kullanicilar?kullaniciId=eq.${_user!.id}'),
        headers: _neuraHeaders(freshToken),
        body: jsonEncode({'sifreHash': yeniSifre}),
      );

      return true;
    } catch (e) {
      debugPrint('Şifre güncelleme hatası: $e');
      return false;
    }
  }

  // ── Yardımcı ─────────────────────────────────────────────
  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}