// lib/services/egzersiz_atama_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'notification_service.dart';

const String _baseUrl = 'https://griteunvazwekosffmjo.supabase.co/rest/v1';
const String _anonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwi'
    'cm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.'
    'q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

Map<String, String> _headers() => {
      'apikey': _anonKey,
      'Authorization': 'Bearer $_anonKey',
      'Accept-Profile': 'neura',
      'Content-Profile': 'neura',
      'Content-Type': 'application/json',
    };

// ─── Model ───────────────────────────────────────────────────────────────────

class EgzersizAtama {
  final int egzersizAtamaId;
  final int hastaId;
  final int? egzersizVideoId;
  final int? klinisyenId;
  final String egzersizAdi;
  final String? notlar;
  final DateTime atamaTarihi;
  final bool tamamlandiMi;

  EgzersizAtama({
    required this.egzersizAtamaId,
    required this.hastaId,
    this.egzersizVideoId,
    this.klinisyenId,
    required this.egzersizAdi,
    this.notlar,
    required this.atamaTarihi,
    required this.tamamlandiMi,
  });

  factory EgzersizAtama.fromJson(Map<String, dynamic> j) => EgzersizAtama(
        egzersizAtamaId: j['egzersizAtamaId'] as int,
        hastaId: j['hastaId'] as int,
        egzersizVideoId: j['egzersizVideoId'] as int?,
        klinisyenId: j['klinisyenId'] as int?,
        egzersizAdi: j['egzersizAdi'] as String,
        notlar: j['notlar'] as String?,
        atamaTarihi: DateTime.parse(j['atamaTarihi'] as String),
        tamamlandiMi: j['tamamlandiMi'] as bool? ?? false,
      );
}

// ─── Service ─────────────────────────────────────────────────────────────────

class EgzersizAtamaService {
  /// Klinisyenin sorumlu olduğu hastalara video ata.
  static Future<void> videoAta({
    required int hastaId,
    required int egzersizVideoId,
    required String egzersizAdi,
    required int klinisyenId,
    String? notlar,
    DateTime? atamaTarihi,
  }) async {
    final body = jsonEncode({
      'hastaId': hastaId,
      'egzersizVideoId': egzersizVideoId,
      'klinisyenId': klinisyenId,
      'egzersizAdi': egzersizAdi,
      if (notlar != null && notlar.isNotEmpty) 'notlar': notlar,
      'atamaTarihi':
          (atamaTarihi ?? DateTime.now()).toIso8601String().substring(0, 10),
    });

    final res = await http.post(
      Uri.parse('$_baseUrl/egzersizAtalari'),
      headers: _headers(),
      body: body,
    );

    if (res.statusCode != 201) {
      throw Exception('Atama başarısız (${res.statusCode}): ${res.body}');
    }
    await NotificationService.createPatientNotificationByHastaId(
      hastaId: hastaId,
      baslik: 'Yeni egzersiz atandı',
      mesaj: 'Klinisyeniniz size yeni bir egzersiz atadı: $egzersizAdi',
    );
  }

  /// Klinisyenin sorumlu olduğu hastaları listele.
  static Future<List<Map<String, dynamic>>> getHastalarByKlinisyen(
      int klinisyenId) async {
    final url = '$_baseUrl/hastalar'
        '?select=hastaId,kullanicilar(ad,soyad)'
        '&klinisyenId=eq.$klinisyenId'
        '&order=hastaId.asc';

    final res = await http.get(Uri.parse(url), headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Hastalar yüklenemedi (${res.statusCode})');
    }
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }

  /// Hastanın kendisine atanan egzersizleri getir.
  static Future<List<EgzersizAtama>> getAtamalarForHasta(int hastaId) async {
    final url = '$_baseUrl/egzersizAtalari'
        '?hastaId=eq.$hastaId'
        '&order=atamaTarihi.desc';

    final res = await http.get(Uri.parse(url), headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Atamalar yüklenemedi (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List;
    return list.map((j) => EgzersizAtama.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Tamamlandı işaretle.
  static Future<void> tamamlandiIsaretle(int egzersizAtamaId) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/egzersizAtalari?egzersizAtamaId=eq.$egzersizAtamaId'),
      headers: _headers(),
      body: jsonEncode({'tamamlandiMi': true}),
    );
    if (res.statusCode != 204) {
      throw Exception('Güncelleme başarısız (${res.statusCode})');
    }
  }
}
