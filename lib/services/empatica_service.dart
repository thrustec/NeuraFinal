import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/biyo_sensor_model.dart';
import '../models/evaluation_model.dart';

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

class EmpaticaService {

  /// Hastanın Empatica biyosensör verilerini getirir
  /// Tablo: neura.biyosensorVerileri
  static Future<List<BiyoSensorVeri>> getBiyoSensorVerileri(
      int hastaId) async {
    try {
      final url =
          '$SUPABASE_URL/biyosensorVerileri'
          '?hastaId=eq.$hastaId'
          '&select=*'
          '&order=olcumZamani.desc';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> liste = json.decode(response.body);
        return liste
            .map((j) => BiyoSensorVeri.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Sensör verileri yüklenemedi.');
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  /// Hastanın değerlendirme geçmişini getirir
  /// Tablo: neura.degerlendirmeler + neura.hastaliklar join
  static Future<List<Evaluation>> getDegerlendirmeler(
      int hastaId) async {
    try {
      final select = Uri.encodeComponent(
        '*,hastaliklar(hastalikAdi)',
      );
      final url =
          '$SUPABASE_URL/degerlendirmeler'
          '?hastaId=eq.$hastaId'
          '&select=$select'
          '&order=degerlendirmeTarihi.desc';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> liste = json.decode(response.body);
        return liste.map((j) {
          final map = j as Map<String, dynamic>;
          // hastaliklar join'ını düzleştir
          final h = map['hastaliklar'];
          if (h is Map<String, dynamic>) {
            map['hastalikAdi'] = h['hastalikAdi'];
          }
          return Evaluation.fromJson(map);
        }).toList();
      }
      throw Exception('Değerlendirmeler yüklenemedi.');
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }
}