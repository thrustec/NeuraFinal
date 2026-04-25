// lib/services/api_client.dart
//
// Supabase REST API ile http paketi üzerinden iletişim kurar.
// Arkadaşının api_client.dart'ından alındı, Supabase header'larına uyarlandı.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _http;

  ApiClient({http.Client? client}) : _http = client ?? http.Client();

  // Supabase REST API için gerekli header'lar
  Map<String, String> _headers({String? select}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Supabase kimlik doğrulama — anon key
      'apikey': ApiConstants.anonKey,
      'Authorization': 'Bearer ${ApiConstants.anonKey}',
      // Supabase'e neura schema'sını kullanmasını söyle
      'Accept-Profile': 'neura',
      'Content-Profile': 'neura',
    };
    // Belirli kolonları seçmek için (örn: select=hastaId,ad,soyad)
    if (select != null) {
      headers['Prefer'] = 'return=representation';
    }
    return headers;
  }

  // GET — veri çekme
  // path örneği: '/hastalar?select=hastaId,ad,soyad&aktifMi=eq.true'
  Future<List<dynamic>> get(String path) async {
    final result = await _execute(() async {
      final uri = Uri.parse('${ApiConstants.baseUrl}$path');
      debugPrint('GET => $uri');
      return _http.get(uri, headers: _headers());
    });
    return result as List<dynamic>;
  }

  // POST — veri ekleme
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    return _execute(() async {
      final uri = Uri.parse('${ApiConstants.baseUrl}$path');
      debugPrint('POST => $uri | BODY => ${jsonEncode(body)}');
      return _http.post(uri,
          headers: _headers(select: '*'), body: jsonEncode(body));
    });
  }

  // PATCH — veri güncelleme
  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    return _execute(() async {
      final uri = Uri.parse('${ApiConstants.baseUrl}$path');
      debugPrint('PATCH => $uri | BODY => ${jsonEncode(body)}');
      return _http.patch(uri,
          headers: _headers(select: '*'), body: jsonEncode(body));
    });
  }

  Future<dynamic> _execute(Future<http.Response> Function() call) async {
    try {
      final response = await call().timeout(const Duration(seconds: 30));
      return _parse(response);
    } on SocketException {
      throw ApiException(
          message: 'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Beklenmeyen hata: $e');
    }
  }

  dynamic _parse(http.Response response) {
    final statusCode = response.statusCode;
    debugPrint('RESPONSE [$statusCode] => ${response.body}');

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return [];
      try {
        final decoded = jsonDecode(response.body);
        // Supabase her zaman liste döner — tek kayıt için de liste gelir
        if (decoded is List) return decoded;
        return [decoded];
      } catch (_) {
        return [];
      }
    }

    String message = 'Sunucu hatası ($statusCode)';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      message = decoded['message'] as String? ??
          decoded['error'] as String? ??
          decoded['msg'] as String? ??
          message;
    } catch (_) {}

    throw ApiException(message: message, statusCode: statusCode);
  }
}