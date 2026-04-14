import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient_model.dart';

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

Map<String, String> _headers({bool write = false}) {
  final h = {
    'apikey': SUPABASE_ANON_KEY,
    'Authorization': 'Bearer $SUPABASE_ANON_KEY',
    'Accept-Profile': 'neura',
    'Content-Type': 'application/json',
  };
  if (write) {
    h['Content-Profile'] = 'neura';
    h['Prefer'] = 'return=representation';
  }
  return h;
}
// ───────────────────────────────────────────────────────────

class PatientService {

  /// Tüm hastaları getirir (lookup tablolarıyla birlikte)
  static Future<List<Patient>> getHastalar({String? aramaMetni}) async {
    try {
      // PostgREST select: hastalar + kullanicilar(ad,soyad,eposta) + lookup tabloları
      // + en son değerlendirmedeki hastalık adı
      final select = Uri.encodeComponent(
        '*,'
            'kullanicilar(ad,soyad,eposta),'
            'cinsiyetler(cinsiyetAdi),'
            'medeniDurumlar(medeniDurumAdi),'
            'egitimDurumlari(egitimDurumAdi),'
            'meslekler(meslekAdi),'
            'degerlendirmeler(hastalikId,hastaliklar(hastalikAdi),klinisyenNotlari)',
      );

      final url = '$SUPABASE_URL/hastalar?select=$select&order=hastaId.asc';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> liste = json.decode(response.body);
        final hastalar = liste.map((j) {
          final map = j as Map<String, dynamic>;
          return Patient.fromJson(_flattenHasta(map));
        }).toList();

        // İstemci tarafı arama (PostgREST ilike de kullanılabilir ama
        // mevcut ekran zaten kendi filtresini yapıyor)
        if (aramaMetni != null && aramaMetni.isNotEmpty) {
          final q = aramaMetni.toLowerCase();
          return hastalar
              .where((h) =>
          h.tamAd.toLowerCase().contains(q) ||
              h.hastaId.toString().contains(q))
              .toList();
        }
        return hastalar;
      }
      throw Exception(
          'Hastalar yüklenemedi. Kod: ${response.statusCode}');
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  /// Tek hasta detayı
  static Future<Patient> getHastaById(int hastaId) async {
    try {
      final select = Uri.encodeComponent(
        '*,'
            'kullanicilar(ad,soyad,eposta),'
            'cinsiyetler(cinsiyetAdi),'
            'medeniDurumlar(medeniDurumAdi),'
            'egitimDurumlari(egitimDurumAdi),'
            'meslekler(meslekAdi),'
            'degerlendirmeler(hastalikId,hastaliklar(hastalikAdi),klinisyenNotlari)',
      );
      final url =
          '$SUPABASE_URL/hastalar?select=$select&hastaId=eq.$hastaId';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> liste = json.decode(response.body);
        if (liste.isEmpty) throw Exception('Hasta bulunamadı.');
        return Patient.fromJson(
            _flattenHasta(liste.first as Map<String, dynamic>));
      }
      throw Exception('Hasta bulunamadı.');
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  /// Hasta bilgilerini güncelle (boy, kilo, klinisyenNotlari vb.)
  static Future<bool> hastaGuncelle(
      int hastaId, Map<String, dynamic> data) async {
    try {
      // klinisyenNotlari degerlendirmeler tablosunda,
      // boy/kilo hastalar tablosunda — ikisini ayırıyoruz
      final hastaData = <String, dynamic>{};
      if (data.containsKey('boy')) hastaData['boy'] = data['boy'];
      if (data.containsKey('kilo')) hastaData['kilo'] = data['kilo'];

      // Hastalar tablosunu güncelle
      if (hastaData.isNotEmpty) {
        final response = await http.patch(
          Uri.parse(
              '$SUPABASE_URL/hastalar?hastaId=eq.$hastaId'),
          headers: _headers(write: true),
          body: json.encode(hastaData),
        );
        if (response.statusCode != 200 &&
            response.statusCode != 204) {
          throw Exception('Hasta güncellenemedi.');
        }
      }

      return true;
    } catch (e) {
      throw Exception('Güncelleme başarısız: $e');
    }
  }

  /// Supabase'den gelen iç içe JSON'u Patient.fromJson'un
  /// beklediği düz yapıya çevirir.
  static Map<String, dynamic> _flattenHasta(Map<String, dynamic> raw) {
    final flat = Map<String, dynamic>.from(raw);

    // kullanicilar → ad, soyad, eposta
    final k = raw['kullanicilar'];
    if (k is Map<String, dynamic>) {
      flat['ad']     = k['ad']     ?? '';
      flat['soyad']  = k['soyad']  ?? '';
      flat['eposta'] = k['eposta'];
    }

    // lookup tablolar
    final c = raw['cinsiyetler'];
    if (c is Map) flat['cinsiyetAdi'] = c['cinsiyetAdi'];

    final m = raw['medeniDurumlar'];
    if (m is Map) flat['medeniDurumAdi'] = m['medeniDurumAdi'];

    final e = raw['egitimDurumlari'];
    if (e is Map) flat['egitimDurumAdi'] = e['egitimDurumAdi'];

    final mes = raw['meslekler'];
    if (mes is Map) flat['meslekAdi'] = mes['meslekAdi'];

    // degerlendirmeler → en son kaydın hastalıkAdı ve klinisyenNotlari
    final degList = raw['degerlendirmeler'];
    if (degList is List && degList.isNotEmpty) {
      final son = degList.first as Map<String, dynamic>;
      final h = son['hastaliklar'];
      if (h is Map) flat['hastalikAdi'] = h['hastalikAdi'];
      flat['klinisyenNotlari'] = son['klinisyenNotlari'];
    }

    // İç içe nesneleri temizle
    flat.remove('kullanicilar');
    flat.remove('cinsiyetler');
    flat.remove('medeniDurumlar');
    flat.remove('egitimDurumlari');
    flat.remove('meslekler');
    flat.remove('degerlendirmeler');

    return flat;
  }
}