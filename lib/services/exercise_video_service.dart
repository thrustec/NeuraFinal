import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/exercise_video_model.dart';

// ─────────────────────────────────────────────────────────────
// Supabase PostgREST — dogrudan bağlantı
// ─────────────────────────────────────────────────────────────
const String SUPABASE_URL =
    'https://griteunvazwekosffmjo.supabase.co/rest/v1';
const String SUPABASE_STORAGE_URL =
    'https://griteunvazwekosffmjo.supabase.co/storage/v1';
const String SUPABASE_ANON_KEY =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwi'
    'cm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.'
    'q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

Map<String, String> _headers() => {
  'apikey': SUPABASE_ANON_KEY,
  'Authorization': 'Bearer $SUPABASE_ANON_KEY',
  'Accept-Profile': 'neura',
  'Content-Type': 'application/json',
};

class ExerciseVideoService {
  /// Egzersiz videolarını Supabase'den çeker.
  static Future<List<EgzersizVideo>> getVideolar({
    int? kategoriId,
    String? aramaMetni,
  }) async {
    try {
      final select = Uri.encodeComponent('*,egzersizKategorileri(kategoriAdi)');
      String url =
          '$SUPABASE_URL/egzersizVideolari'
          '?select=$select'
          '&aktifMi=eq.true'
          '&order=egzersizVideoId.asc';

      if (kategoriId != null) url += '&kategoriId=eq.$kategoriId';

      final response = await http.get(Uri.parse(url), headers: _headers());

      if (response.statusCode == 200) {
        final List<dynamic> liste = json.decode(response.body);
        List<EgzersizVideo> videolar =
        liste.map((j) => EgzersizVideo.fromJson(j as Map<String, dynamic>)).toList();

        if (aramaMetni != null && aramaMetni.isNotEmpty) {
          final q = aramaMetni.toLowerCase();
          videolar = videolar
              .where((v) =>
          v.baslik.toLowerCase().contains(q) ||
              (v.aciklama?.toLowerCase().contains(q) ?? false) ||
              (v.kategoriAdi?.toLowerCase().contains(q) ?? false))
              .toList();
        }
        return videolar;
      }
      throw Exception('Videolar yuklenemedi. Kod: ${response.statusCode}');
    } catch (e) {
      throw Exception('Baglanti hatasi: $e');
    }
  }

  /// Egzersiz kategorilerini Supabase'den çeker.
  static Future<List<EgzersizKategori>> getKategoriler() async {
    try {
      final url =
          '$SUPABASE_URL/egzersizKategorileri'
          '?select=*'
          '&aktifMi=eq.true'
          '&order=egzersizKategoriId.asc';

      final response = await http.get(Uri.parse(url), headers: _headers());

      if (response.statusCode == 200) {
        final List<dynamic> liste = json.decode(response.body);
        return liste.map((j) => EgzersizKategori.fromJson(j as Map<String, dynamic>)).toList();
      }
      throw Exception('Kategoriler yuklenemedi. Kod: ${response.statusCode}');
    } catch (e) {
      throw Exception('Baglanti hatasi: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPLOAD — Storage
  // ─────────────────────────────────────────────────────────────

  /// Dosyayı Supabase Storage'a yükler, public URL döner.
  static Future<String> uploadDosya({
    required File dosya,
    required String bucket,
    required String klasor,
  }) async {
    final dosyaYolu = dosya.path;
    final uzanti = dosyaYolu.contains('.') ? '.${dosyaYolu.split('.').last}' : '';
    final dosyaAdi = '${klasor}_${DateTime.now().millisecondsSinceEpoch}$uzanti';
    final yol = '$klasor/$dosyaAdi';

    final bytes = await dosya.readAsBytes();
    final mimeType = _mimeType(uzanti);

    final url = Uri.parse('$SUPABASE_STORAGE_URL/object/$bucket/$yol');
    final response = await http.post(
      url,
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': 'Bearer $SUPABASE_ANON_KEY',
        'Content-Type': mimeType,
        'x-upsert': 'true',
      },
      body: bytes,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Storage hatasi (${response.statusCode}): ${response.body}');
    }

    return '$SUPABASE_STORAGE_URL/object/public/$bucket/$yol';
  }

  // ─────────────────────────────────────────────────────────────
  // INSERT & UPDATE — veritabanı işlemleri
  // ─────────────────────────────────────────────────────────────

  /// Yeni egzersiz videosunu neura.egzersizVideolari tablosuna kaydeder.
  static Future<void> videoKaydet({
    required String baslik,
    String? aciklama,
    required int kategoriId,
    required int yukleyenId,
    required String videoUrl,
    String? thumbnailUrl,
    required int sureSaniye,
  }) async {
    final body = json.encode({
      'baslik': baslik,
      if (aciklama != null) 'aciklama': aciklama,
      'kategoriId': kategoriId,
      'yukleyenId': yukleyenId,
      'videoUrl': videoUrl,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      'sureSaniye': sureSaniye,
      'aktifMi': true,
    });

    final response = await http.post(
      Uri.parse('$SUPABASE_URL/egzersizVideolari'),
      headers: {
        ..._headers(),
        'Content-Profile': 'neura',
        'Prefer': 'return=minimal',
      },
      body: body,
    );

    if (response.statusCode != 201) {
      throw Exception('Kayit hatasi (${response.statusCode}): ${response.body}');
    }
  }

  /// Videoyu pasife çeker (soft delete)
  static Future<void> videoSil(int videoId) async {
    final url = Uri.parse('$SUPABASE_URL/egzersizVideolari?egzersizVideoId=eq.$videoId');
    final response = await http.patch(
      url,
      headers: {
        ..._headers(),
        'Content-Profile': 'neura',
        'Prefer': 'return=minimal',
      },
      body: json.encode({'aktifMi': false}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Silme hatasi (${response.statusCode}): ${response.body}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Yardımcı
  // ─────────────────────────────────────────────────────────────

  static String _mimeType(String uzanti) {
    switch (uzanti.toLowerCase()) {
      case '.mp4':  return 'video/mp4';
      case '.mov':  return 'video/quicktime';
      case '.avi':  return 'video/x-msvideo';
      case '.jpg':
      case '.jpeg': return 'image/jpeg';
      case '.png':  return 'image/png';
      case '.webp': return 'image/webp';
      default:      return 'application/octet-stream';
    }
  }
}