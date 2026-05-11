import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  static const String _baseUrl = 'https://griteunvazwekosffmjo.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

  static const int _rolIdKlinisyen = 1;
  static const int _rolIdHasta = 2;

  static const Map<String, String> _authHeaders = {
    'Content-Type': 'application/json',
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
  };

  Map<String, String> _restHeaders(String token) => {
    'Content-Type': 'application/json',
    'apikey': _anonKey,
    'Authorization': 'Bearer ${token.isNotEmpty ? token : _anonKey}',
    'Accept-Profile': 'neura',
    'Content-Profile': 'neura',
    'Prefer': 'return=representation',
  };

  Map<String, String> _restGetHeaders(String token) => {
    'Content-Type': 'application/json',
    'apikey': _anonKey,
    'Authorization': 'Bearer ${token.isNotEmpty ? token : _anonKey}',
    'Accept-Profile': 'neura',
  };

  static Map<String, String> get _staticGetHeaders => {
    'Content-Type': 'application/json',
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Accept-Profile': 'neura',
  };

  String _rolAdiFromId(int rolId) =>
      rolId == _rolIdKlinisyen ? 'Klinisyen' : 'Hasta';

  int _rolIdFromAdi(String rolAdi) =>
      rolAdi == 'Klinisyen' ? _rolIdKlinisyen : _rolIdHasta;

  // ============================================================================
  // Klinisyen listesini getir
  // ============================================================================
  static Future<List<Map<String, dynamic>>> getKlinisyenler() async {
    try {
      final url = '$_baseUrl/rest/v1/klinisyenler'
          '?select=klinisyenId,unvan,kullanicilar(ad,soyad)'
          '&aktifMi=eq.true'
          '&order=klinisyenId.asc';

      final response = await http
          .get(Uri.parse(url), headers: _staticGetHeaders)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> liste = jsonDecode(response.body);
        return liste.map<Map<String, dynamic>>((item) {
          final map = item as Map<String, dynamic>;
          final k = map['kullanicilar'] as Map<String, dynamic>?;
          return {
            'klinisyenId': map['klinisyenId'],
            'unvan': map['unvan'] ?? '',
            'ad': k?['ad'] ?? '',
            'soyad': k?['soyad'] ?? '',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('[getKlinisyenler] Hata: $e');
      return [];
    }
  }

  // ============================================================================
  // kullaniciId → klinisyenId
  // ============================================================================
  static Future<int?> getKlinisyenIdByKullaniciId(int kullaniciId) async {
    try {
      final url = '$_baseUrl/rest/v1/klinisyenler'
          '?select=klinisyenId'
          '&kullaniciId=eq.$kullaniciId'
          '&limit=1';

      final response = await http
          .get(Uri.parse(url), headers: _staticGetHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> liste = jsonDecode(response.body);
        if (liste.isNotEmpty) {
          return (liste.first as Map<String, dynamic>)['klinisyenId'] as int?;
        }
      }
      return null;
    } catch (e) {
      print('[getKlinisyenIdByKullaniciId] Hata: $e');
      return null;
    }
  }

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

      // 2. kullanicilar tablosundan kullanıcıyı bul
      final userRes = await http
          .get(
        Uri.parse(
            '$_baseUrl/rest/v1/kullanicilar?eposta=eq.$eposta&select=kullaniciId,ad,soyad,eposta,rolId'),
        headers: _restGetHeaders(token),
      )
          .timeout(const Duration(seconds: 30));

      print('[LOGIN] kullanicilar => ${userRes.statusCode}: ${userRes.body}');

      if (userRes.statusCode != 200) throw Exception('GEÇERSİZ_GİRİŞ');

      final users = jsonDecode(userRes.body) as List;
      if (users.isEmpty) throw Exception('GEÇERSİZ_GİRİŞ');

      final user = users.first as Map<String, dynamic>;
      final int rolId = (user['rolId'] as int?) ?? _rolIdHasta;
      final int kullaniciId = user['kullaniciId'] as int;
      final String rolAdi = _rolAdiFromId(rolId);

      // 3. Klinisyen ise unvan + klinisyenId çek
      String? unvan;
      int? klinisyenId;

      if (rolId == _rolIdKlinisyen) {
        final clinRes = await http
            .get(
          Uri.parse(
              '$_baseUrl/rest/v1/klinisyenler?kullaniciId=eq.$kullaniciId&select=klinisyenId,unvan'),
          headers: _restGetHeaders(token),
        )
            .timeout(const Duration(seconds: 30));

        print('[LOGIN] klinisyenler => ${clinRes.statusCode}: ${clinRes.body}');

        if (clinRes.statusCode == 200) {
          final list = jsonDecode(clinRes.body) as List;
          if (list.isNotEmpty) {
            final c = list.first as Map<String, dynamic>;
            unvan       = c['unvan'] as String?;
            klinisyenId = c['klinisyenId'] as int?; // ← klinisyenId alındı
          }
        }
      }

      return UserModel.fromJson({
        'id':          kullaniciId.toString(),
        'ad':          user['ad'] ?? '',
        'soyad':       user['soyad'] ?? '',
        'eposta':      user['eposta'] ?? eposta,
        'rolId':       rolId,
        'rolAdi':      rolAdi,
        'token':       token,
        'unvan':       unvan,
        'klinisyenId': klinisyenId, // ← UserModel'e geçirildi
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
    int? klinisyenId,
  }) async {
    try {
      final int rolId = _rolIdFromAdi(rolAdi);

      // ADIM 1: Supabase Auth signup
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
      final token = authData['access_token'] as String? ?? '';

      print('[REGISTER] access_token boş mu: ${token.isEmpty}');

      // ADIM 2: kullanicilar tablosuna ekle
      int? kullaniciId = await _getKullaniciId(eposta, token);

      if (kullaniciId != null) {
        print('[REGISTER] Trigger zaten ekledi, kullaniciId: $kullaniciId');
      } else {
        print('[REGISTER] Manuel kullanicilar insert basliyor...');
        final insertRes = await http
            .post(
          Uri.parse('$_baseUrl/rest/v1/kullanicilar'),
          headers: _restHeaders(token),
          body: jsonEncode({
            'ad':       ad,
            'soyad':    soyad,
            'eposta':   eposta,
            'sifreHash': sifre,
            'rolId':    rolId,
            'aktifMi':  true,
          }),
        )
            .timeout(const Duration(seconds: 30));

        print('[REGISTER] kullanicilar insert => ${insertRes.statusCode}: ${insertRes.body}');

        if (insertRes.statusCode >= 200 && insertRes.statusCode < 300) {
          kullaniciId = _extractId(insertRes.body, 'kullaniciId');
        } else {
          print('[REGISTER] UYARI: kullanicilar insert basarisiz. Yanit: ${insertRes.body}');
        }
      }

      // ADIM 3: Klinisyen ise klinisyenler tablosuna ekle
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

      // ADIM 4: Hasta ise hastalar tablosuna ekle
      if (rolId == _rolIdHasta && kullaniciId != null) {
        try {
          final hastaBody = <String, dynamic>{'kullaniciId': kullaniciId};
          if (klinisyenId != null) {
            hastaBody['klinisyenId'] = klinisyenId;
          }

          final hastaRes = await http
              .post(
            Uri.parse('$_baseUrl/rest/v1/hastalar'),
            headers: _restHeaders(token),
            body: jsonEncode(hastaBody),
          )
              .timeout(const Duration(seconds: 30));

          print('[REGISTER] hastalar => ${hastaRes.statusCode}: ${hastaRes.body}');
        } catch (e) {
          print('[REGISTER] hastalar insert atlandi: $e');
        }
      }

      return UserModel.fromJson({
        'id':    (kullaniciId ?? authData['user']?['id'] ?? '').toString(),
        'ad':    ad,
        'soyad': soyad,
        'eposta': eposta,
        'rolId':  rolId,
        'rolAdi': rolAdi,
        'token':  token,
        'unvan':  unvan,
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

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}