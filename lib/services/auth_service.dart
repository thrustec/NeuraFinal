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

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Accept-Profile': 'neura',
    'Content-Profile': 'neura',
  };

  String _rolAdiFromId(int rolId) =>
      rolId == _rolIdKlinisyen ? 'Klinisyen' : 'Hasta';

  int _rolIdFromAdi(String rolAdi) =>
      rolAdi == 'Klinisyen' ? _rolIdKlinisyen : _rolIdHasta;

  // =====================
  // GİRİŞ YAP
  // =====================
  Future<UserModel> login(String eposta, String sifre) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/v1/token?grant_type=password'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
        body: jsonEncode({
          'email': eposta,
          'password': sifre,
        }),
      ).timeout(const Duration(seconds: 30));

      print('Login response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'] ?? '';
        final userInfo = data['user'];

        // Kullanıcı bilgilerini kullanicilar tablosundan çek
        final userResponse = await http.get(
          Uri.parse(
              '$_baseUrl/rest/v1/kullanicilar?eposta=eq.$eposta&select=kullaniciId,ad,soyad,eposta,rolId'),
          headers: {
            ..._headers,
            'Authorization': 'Bearer $accessToken',
          },
        ).timeout(const Duration(seconds: 30));

        print('User response: ${userResponse.statusCode} ${userResponse.body}');

        if (userResponse.statusCode == 200) {
          final users = jsonDecode(userResponse.body) as List;
          if (users.isNotEmpty) {
            final user = users.first;
            final int rolId = user['rolId'] as int? ?? _rolIdHasta;
            final String rolAdi = _rolAdiFromId(rolId);
            final int kullaniciId = user['kullaniciId'] as int;

            // Klinisyen ise klinisyenler tablosundan ek bilgi çek
            String? unvan;
            String? uzmanlikAlani;
            String? kurumAdi;
            String? telefonNo;

            if (rolId == _rolIdKlinisyen) {
              final clinicianRes = await http.get(
                Uri.parse(
                    '$_baseUrl/rest/v1/klinisyenler?kullaniciId=eq.$kullaniciId&select=unvan,uzmanlikAlani,telefonNo,kurumAdi'),
                headers: {
                  ..._headers,
                  'Authorization': 'Bearer $accessToken',
                },
              ).timeout(const Duration(seconds: 30));

              if (clinicianRes.statusCode == 200) {
                final list = jsonDecode(clinicianRes.body) as List;
                if (list.isNotEmpty) {
                  final c = list.first as Map<String, dynamic>;
                  unvan = c['unvan'] as String?;
                  uzmanlikAlani = c['uzmanlikAlani'] as String?;
                  telefonNo = c['telefonNo'] as String?;
                  kurumAdi = c['kurumAdi'] as String?;
                }
              }
            }

            return UserModel.fromJson({
              'id': kullaniciId.toString(),
              'ad': user['ad'] ?? '',
              'soyad': user['soyad'] ?? '',
              'eposta': user['eposta'] ?? eposta,
              'telefon': telefonNo ?? '',
              'rolId': rolId,
              'rolAdi': rolAdi,
              'token': accessToken,
              'unvan': unvan,
              'uzmanlikAlani': uzmanlikAlani,
              'kurumAdi': kurumAdi,
            });
          }
        }

        // Kullanıcı tablosunda bulunamazsa auth bilgilerinden oluştur
        return UserModel.fromJson({
          'id': userInfo?['id']?.toString() ?? '',
          'ad': eposta.split('@').first,
          'soyad': '',
          'eposta': eposta,
          'telefon': '',
          'rolId': _rolIdHasta,
          'rolAdi': 'Hasta',
          'token': accessToken,
        });
      } else if (response.statusCode == 400) {
        throw Exception('GEÇERSİZ_GİRİŞ');
      } else {
        throw Exception('BAĞLANTI_HATASI: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('BAĞLANTI_HATASI');
    } catch (e) {
      print('Login hata: $e');
      if (e.toString().contains('GEÇERSİZ_GİRİŞ')) rethrow;
      throw Exception('BAĞLANTI_HATASI');
    }
  }

  // =====================
  // KAYIT OL
  // =====================
  Future<UserModel> register({
    required String ad,
    required String soyad,
    required String eposta,
    required String telefon,
    required String sifre,
    required String rolAdi,
    // Klinisyen alanları (rolAdi == 'Klinisyen' iken kullanılır)
    String? unvan,
    String? uzmanlikAlani,
    String? kurumAdi,
  }) async {
    try {
      // 1. Supabase Auth ile kullanıcı oluştur
      final authResponse = await http.post(
        Uri.parse('$_baseUrl/auth/v1/signup'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
        body: jsonEncode({
          'email': eposta,
          'password': sifre,
        }),
      ).timeout(const Duration(seconds: 30));

      print('Register response: ${authResponse.statusCode} ${authResponse.body}');

      if (authResponse.statusCode == 200 || authResponse.statusCode == 201) {
        final authData = jsonDecode(authResponse.body);
        final accessToken = authData['access_token'] ?? '';

        final int rolId = _rolIdFromAdi(rolAdi);

        // 2. kullanicilar tablosuna kaydet
        final userResponse = await http.post(
          Uri.parse('$_baseUrl/rest/v1/kullanicilar'),
          headers: {
            ..._headers,
            'Authorization':
                'Bearer ${accessToken.isNotEmpty ? accessToken : _anonKey}',
            'Prefer': 'return=representation',
          },
          body: jsonEncode({
            'ad': ad,
            'soyad': soyad,
            'eposta': eposta,
            'sifreHash': sifre,
            'rolId': rolId,
            'aktifMi': true,
          }),
        ).timeout(const Duration(seconds: 30));

        print(
            'User insert response: ${userResponse.statusCode} ${userResponse.body}');

        // 3. Klinisyen ise klinisyenler tablosuna ek satır
        int? kullaniciId;
        if (userResponse.statusCode >= 200 && userResponse.statusCode < 300) {
          try {
            final inserted = jsonDecode(userResponse.body);
            if (inserted is List && inserted.isNotEmpty) {
              kullaniciId = inserted.first['kullaniciId'] as int?;
            } else if (inserted is Map<String, dynamic>) {
              kullaniciId = inserted['kullaniciId'] as int?;
            }
          } catch (_) {}
        }

        if (rolId == _rolIdKlinisyen && kullaniciId != null) {
          await http.post(
            Uri.parse('$_baseUrl/rest/v1/klinisyenler'),
            headers: {
              ..._headers,
              'Authorization':
                  'Bearer ${accessToken.isNotEmpty ? accessToken : _anonKey}',
              'Prefer': 'return=representation',
            },
            body: jsonEncode({
              'kullaniciId': kullaniciId,
              'unvan': (unvan ?? '').trim().isEmpty ? null : unvan!.trim(),
              'uzmanlikAlani': (uzmanlikAlani ?? '').trim().isEmpty
                  ? null
                  : uzmanlikAlani!.trim(),
              'telefonNo': telefon.trim().isEmpty ? null : telefon.trim(),
              'kurumAdi':
                  (kurumAdi ?? '').trim().isEmpty ? null : kurumAdi!.trim(),
              'aktifMi': true,
            }),
          ).timeout(const Duration(seconds: 30));
        }

        return UserModel.fromJson({
          'id': (kullaniciId ?? authData['user']?['id'] ?? '').toString(),
          'ad': ad,
          'soyad': soyad,
          'eposta': eposta,
          'telefon': telefon,
          'rolId': rolId,
          'rolAdi': rolAdi,
          'token': accessToken,
          'unvan': unvan,
          'uzmanlikAlani': uzmanlikAlani,
          'kurumAdi': kurumAdi,
        });
      } else if (authResponse.statusCode == 422) {
        throw Exception('EMAIL_KAYITLI');
      } else {
        throw Exception('BAĞLANTI_HATASI: ${authResponse.statusCode}');
      }
    } on SocketException {
      throw Exception('BAĞLANTI_HATASI');
    } catch (e) {
      print('Register hata: $e');
      if (e.toString().contains('EMAIL_KAYITLI')) rethrow;
      if (e.toString().contains('BAĞLANTI_HATASI')) rethrow;
      throw Exception('BAĞLANTI_HATASI');
    }
  }

  // =====================
  // ÇIKIŞ YAP
  // =====================
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
