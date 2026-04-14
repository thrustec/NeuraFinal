import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exercise_video_model.dart';

// ─────────────────────────────────────────────────────────────
// Supabase PostgREST — doğrudan bağlantı
// ─────────────────────────────────────────────────────────────
const String SUPABASE_URL =
    'https://griteunvazwekosffmjo.supabase.co/rest/v1';
const String SUPABASE_ANON_KEY =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwi'
    'cm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.'
    'q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

Map<String, String> _headers() {
  return {
    'apikey': SUPABASE_ANON_KEY,
    'Authorization': 'Bearer $SUPABASE_ANON_KEY',
    'Accept-Profile': 'neura',
    'Content-Type': 'application/json',
  };
}
// ──────────────────────────────────────────────────────────

class ExerciseVideoService {
  /// Egzersiz videolarını Supabase'den çeker.
  /// egzersizKategorileri tablosuyla join yaparak kategoriAdi alır.
  /// Sadece aktif videoları (aktifMi = true) getirir.
  static Future<List<EgzersizVideo>> getVideolar({
    int? kategoriId,
    String? aramaMetni,
  }) async {
    try {
      final select = Uri.encodeComponent(
        '*,egzersizKategorileri(kategoriAdi)',
      );
      String url =
          '$SUPABASE_URL/egzersizVideolari'
          '?select=$select'
          '&aktifMi=eq.true'
          '&order=egzersizVideoId.asc';

      if (kategoriId != null) {
        url += '&kategoriId=eq.$kategoriId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> liste = json.decode(response.body);
        List<EgzersizVideo> videolar = liste
            .map((j) =>
            EgzersizVideo.fromJson(j as Map<String, dynamic>))
            .toList();

        // İstemci tarafı metin araması
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
      throw Exception(
          'Videolar yuklenemedi. Kod: ${response.statusCode}');
    } catch (e) {
      throw Exception('Baglanti hatasi: $e');
    }
  }

  /// Egzersiz kategorilerini Supabase'den çeker.
  /// Tablo: neura.egzersizKategorileri
  static Future<List<EgzersizKategori>> getKategoriler() async {
    try {
      final url =
          '$SUPABASE_URL/egzersizKategorileri'
          '?select=*'
          '&aktifMi=eq.true'
          '&order=egzersizKategoriId.asc';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> liste = json.decode(response.body);
        return liste
            .map((j) =>
            EgzersizKategori.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      throw Exception(
          'Kategoriler yuklenemedi. Kod: ${response.statusCode}');
    } catch (e) {
      throw Exception('Baglanti hatasi: $e');
    }
  }
}
