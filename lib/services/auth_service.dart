import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  static const String _baseUrl = 'https://griteunvazwekosffmjo.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

  // Rol ID eşleştirmesi (DB: 1=Klinisyen, 2=Hasta)
  static const int _rolIdKlinisyen = 1;
  static const int _rolIdHasta = 2;

  // ── Auth endpoint headers (schema yok) ──────────────────────────────────────
  static const Map<String, String> _authHeaders = {
    'Content-Type': 'application/json',
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
  };

  // ── neura schema REST headers (token ile) ───────────────────────────────────
  Map<String, String> _restHeaders(String token) => {
    'Content-Type': 'application/json',
    'apikey': _anonKey,
    'Authorization': 'Bearer ${token.isNotEmpty ? token : _anonKey}',
    'Accept-Profile': 'neura',
    'Content-Profile': 'neura',
    'Prefer': 'return=representation',
  };

  // ── neura schema REST headers (GET — Prefer olmadan) ────────────────────────
  Map<String, String> _restGetHeaders(String token) => {
    'Content-Type': 'application/json',
    'apikey': _anonKey,
    'Authorization': 'Bearer ${token.isNotEmpty ? token : _anonKey}',
    'Accept-Profile': 'neura',
  };

  String _rolAdiFromId(int rolId) =>
      rolId == _rolIdKlinisyen ? 'Klinisyen' : 'Hasta';

  int _rolIdFromAdi(String rolAdi) =>
      rolAdi == 'Klinisyen' ? _rolIdKlinisyen : _rolIdHasta;

  // ============================================================================
  // GİRİŞ YAP
  // ============================================================================
  Future<UserModel> login(String eposta, String sifre) async {
    try {
      // 1. Auth token al
      final authRes = await http
          .post(
        Uri.parse('$_baseUrl/auth/v1/token?grant_type=password'),
        headers: _authHeaders,
        body: jsonEncode({'email': eposta, 'password': sifre}),
      )
          .timeout(const Duration(seconds: 30));

      print('[LOGIN] auth/v1/token => ${authRes.statusCode}: ${authRes.body}');

      if (authRes.statusCode != 200) {
        if (authRes.statusCode == 400) throw Exception('GEÇERSİZ_GİRİŞ');
        throw Exception('BAĞLANTI_HATASI: ${authRes.statusCode}');
      }

      final authData = jsonDecode(authRes.body) as Map<String, dynamic>;
      final token = authData['access_token'] as String? ?? '';

      // 2. neura.kullanicilar'dan kullanıcıyı bul
      final userRes = await http
          .get(
        Uri.parse(
            '$_baseUrl/rest/v1/kullanicilar?eposta=eq.$eposta&select=kullaniciId,ad,soyad,eposta,rolId'),
        headers: _restGetHeaders(token),
      )
          .timeout(const Duration(seconds: 30));

      print('[LOGIN] kullanicilar => ${userRes.statusCode}: ${userRes.body}');

      if (userRes.statusCode != 200) {
        throw Exception('GEÇERSİZ_GİRİŞ');
      }

      final users = jsonDecode(userRes.body) as List;
      if (users.isEmpty) {
        // Auth'ta var ama DB'de yok
        throw Exception('GEÇERSİZ_GİRİŞ');
      }

      final user = users.first as Map<String, dynamic>;
      final int rolId = (user['rolId'] as int?) ?? _rolIdHasta;
      final int kullaniciId = user['kullaniciId'] as int;
      final String rolAdi = _rolAdiFromId(rolId);

      // 3. Klinisyen ise ek bilgi (sadece unvan kaldı)
      String? unvan;
      if (rolId == _rolIdKlinisyen) {
        final clinRes = await http
            .get(
          Uri.parse(
              '$_baseUrl/rest/v1/klinisyenler?kullaniciId=eq.$kullaniciId&select=unvan'),
          headers: _restGetHeaders(token),
        )
            .timeout(const Duration(seconds: 30));

        print('[LOGIN] klinisyenler => ${clinRes.statusCode}: ${clinRes.body}');

        if (clinRes.statusCode == 200) {
          final list = jsonDecode(clinRes.body) as List;
          if (list.isNotEmpty) {
            final c = list.first as Map<String, dynamic>;
            unvan = c['unvan'] as String?;
          }
        }
      }

      return UserModel.fromJson({
        'id': kullaniciId.toString(),
        'ad': user['ad'] ?? '',
        'soyad': user['soyad'] ?? '',
        'eposta': user['eposta'] ?? eposta,
        'rolId': rolId,
        'rolAdi': rolAdi,
        'token': token,
        'unvan': unvan,
      });
    } on SocketException {
      throw Exception('BAĞLANTI_HATASI');
    } catch (e) {
      print('[LOGIN] Hata: $e');
      if (e.toString().contains('GEÇERSİZ_GİRİŞ')) rethrow;
      throw Exception('BAĞLANTI_HATASI');
    }
  }

  // ============================================================================
  // KAYIT OL
  // ============================================================================
  Future<UserModel> register({
    required String ad,
    required String soyad,
    required String eposta,
    required String sifre,
    required String rolAdi,
    String? unvan,
  }) async {
    try {
      final int rolId = _rolIdFromAdi(rolAdi);

      // ── ADIM 1: Supabase Auth signup ────────────────────────────────────────
      // metadata ekle — trigger varsa okur
      final authRes = await http
          .post(
        Uri.parse('$_baseUrl/auth/v1/signup'),
        headers: _authHeaders,
        body: jsonEncode({
          'email': eposta,
          'password': sifre,
          'data': {'ad': ad, 'soyad': soyad, 'rolId': rolId},
        }),
      )
          .timeout(const Duration(seconds: 30));

      print('[REGISTER] auth/v1/signup => ${authRes.statusCode}: ${authRes.body}');

      if (authRes.statusCode == 422) throw Exception('EMAIL_KAYITLI');
      if (authRes.statusCode != 200 && authRes.statusCode != 201) {
        throw Exception('BAĞLANTI_HATASI: Auth ${authRes.statusCode}');
      }

      final authData = jsonDecode(authRes.body) as Map<String, dynamic>;
      // Email doğrulama kapalıysa token gelir, açıksa boş gelir
      final token = authData['access_token'] as String? ?? '';

      print('[REGISTER] access_token boş mu: ${token.isEmpty}');

      // ── ADIM 2: kullanicilar tablosuna ekle ─────────────────────────────────
      // Önce trigger ekledi mi diye kontrol et
      int? kullaniciId = await _getKullaniciId(eposta, token);

      if (kullaniciId != null) {
        print('[REGISTER] Trigger zaten ekledi, kullaniciId: $kullaniciId');
      } else {
        // Manuel insert
        print('[REGISTER] Manuel kullanicilar insert başlıyor...');
        final insertRes = await http
            .post(
          Uri.parse('$_baseUrl/rest/v1/kullanicilar'),
          headers: _restHeaders(token),
          body: jsonEncode({
            'ad': ad,
            'soyad': soyad,
            'eposta': eposta,
            'sifreHash': sifre,
            'rolId': rolId,
            'aktifMi': true,
          }),
        )
            .timeout(const Duration(seconds: 30));

        print(
            '[REGISTER] kullanicilar insert => ${insertRes.statusCode}: ${insertRes.body}');

        if (insertRes.statusCode >= 200 && insertRes.statusCode < 300) {
          kullaniciId = _extractId(insertRes.body, 'kullaniciId');
        } else {
          // RLS engelledi — service_role key ile tekrar dene
          print(
              '[REGISTER] UYARI: kullanicilar insert başarısız. RLS engelliyor olabilir.');
          print('[REGISTER] Yanıt: ${insertRes.body}');
          // kullaniciId null kalacak, devam ediyoruz
        }
      }

      // ── ADIM 3: Klinisyen ise klinisyenler tablosuna ekle ───────────────────
      if (rolId == _rolIdKlinisyen && kullaniciId != null) {
        final clinRes = await http
            .post(
          Uri.parse('$_baseUrl/rest/v1/klinisyenler'),
          headers: _restHeaders(token),
          body: jsonEncode({
            'kullaniciId': kullaniciId,
            'unvan': (unvan ?? '').trim().isEmpty ? null : unvan!.trim(),
            'aktifMi': true,
          }),
        )
            .timeout(const Duration(seconds: 30));

        print('[REGISTER] klinisyenler => ${clinRes.statusCode}: ${clinRes.body}');
      }

      // ── ADIM 4: Hasta ise hastalar tablosuna boş kayıt ekle ─────────────────
      if (rolId == _rolIdHasta && kullaniciId != null) {
        try {
          final hastaRes = await http
              .post(
            Uri.parse('$_baseUrl/rest/v1/hastalar'),
            headers: _restHeaders(token),
            body: jsonEncode({'kullaniciId': kullaniciId}),
          )
              .timeout(const Duration(seconds: 30));

          print(
              '[REGISTER] hastalar => ${hastaRes.statusCode}: ${hastaRes.body}');
        } catch (e) {
          // hastalar insert başarısız olsa bile kayıt akışı durmasın
          print('[REGISTER] hastalar insert atlandı: $e');
        }
      }

      return UserModel.fromJson({
        'id': (kullaniciId ?? authData['user']?['id'] ?? '').toString(),
        'ad': ad,
        'soyad': soyad,
        'eposta': eposta,
        'rolId': rolId,
        'rolAdi': rolAdi,
        'token': token,
        'unvan': unvan,
      });
    } on SocketException {
      throw Exception('BAĞLANTI_HATASI');
    } catch (e) {
      print('[REGISTER] Hata: $e');
      if (e.toString().contains('EMAIL_KAYITLI')) rethrow;
      if (e.toString().contains('BAĞLANTI_HATASI')) rethrow;
      throw Exception('BAĞLANTI_HATASI');
    }
  }

  // ── Yardımcı: e-postaya göre kullaniciId bul ─────────────────────────────────
  Future<int?> _getKullaniciId(String eposta, String token) async {
    try {
      final res = await http
          .get(
        Uri.parse(
            '$_baseUrl/rest/v1/kullanicilar?eposta=eq.$eposta&select=kullaniciId'),
        headers: _restGetHeaders(token),
      )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (list.isNotEmpty) {
          return list.first['kullaniciId'] as int?;
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Yardımcı: response body'den ID çıkar ────────────────────────────────────
  int? _extractId(String body, String key) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is List && decoded.isNotEmpty) {
        return decoded.first[key] as int?;
      }
      if (decoded is Map<String, dynamic>) {
        return decoded[key] as int?;
      }
    } catch (_) {}
    return null;
  }

  // ============================================================================
  // ÇIKIŞ YAP
  // ============================================================================
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
