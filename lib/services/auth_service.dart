import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  static const String _baseUrl = 'https://griteunvazwekosffmjo.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
  };

  // =====================
  // GİRİŞ YAP
  // =====================
  Future<UserModel> login(String eposta, String sifre) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/v1/token?grant_type=password'),
        headers: _headers,
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
              '$_baseUrl/rest/v1/kullanicilar?eposta=eq.$eposta&select=*,roller(rolAdi)'),
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
            return UserModel.fromJson({
              'id': user['kullaniciId']?.toString() ?? '',
              'ad': user['ad'] ?? '',
              'soyad': user['soyad'] ?? '',
              'eposta': user['eposta'] ?? eposta,
              'telefon': '',
              'rolId': user['rolId'] ?? 1,
              'rolAdi': user['roller']?['rolAdi'] ?? 'Hasta',
              'token': accessToken,
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
          'rolId': 1,
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
  }) async {
    try {
      // 1. Supabase Auth ile kullanıcı oluştur
      final authResponse = await http.post(
        Uri.parse('$_baseUrl/auth/v1/signup'),
        headers: _headers,
        body: jsonEncode({
          'email': eposta,
          'password': sifre,
        }),
      ).timeout(const Duration(seconds: 30));

      print('Register response: ${authResponse.statusCode} ${authResponse.body}');

      if (authResponse.statusCode == 200 || authResponse.statusCode == 201) {
        final authData = jsonDecode(authResponse.body);
        final accessToken = authData['access_token'] ?? '';

        // 2. Rol ID'sini bul
        final rolId = rolAdi == 'Klinisyen' ? 2 : 1;

        // 3. kullanicilar tablosuna kaydet
        final userResponse = await http.post(
          Uri.parse('$_baseUrl/rest/v1/kullanicilar'),
          headers: {
            ..._headers,
            'Authorization': 'Bearer ${accessToken.isNotEmpty ? accessToken : _anonKey}',
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

        print('User insert response: ${userResponse.statusCode} ${userResponse.body}');

        return UserModel.fromJson({
          'id': authData['user']?['id']?.toString() ?? '',
          'ad': ad,
          'soyad': soyad,
          'eposta': eposta,
          'telefon': telefon,
          'rolId': rolId,
          'rolAdi': rolAdi,
          'token': accessToken,
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