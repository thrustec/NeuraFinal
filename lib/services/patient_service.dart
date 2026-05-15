import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient_model.dart';
import 'package:flutter/foundation.dart';

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

  /// Tüm hastaları getirir.
  /// [klinisyenId] verilirse yalnızca o klinisyene atanmış hastalar döner.
  static Future<List<Patient>> getHastalar({
    String? aramaMetni,
    int? klinisyenId,
  }) async {
    try {
      final basicPatients = await _fetchPatientsBasic(klinisyenId: klinisyenId);
      final patients = klinisyenId == null
          ? basicPatients
          : await _appendLegacyPatients(basicPatients, klinisyenId);
      return _filterPatients(patients, aramaMetni);
    } catch (e) {
      debugPrint('PatientService.getHastalar basic fetch failed: $e');
      final detailedPatients = await _fetchPatientsDetailed(klinisyenId: klinisyenId);
      final patients = klinisyenId == null
          ? detailedPatients
          : await _appendLegacyPatients(detailedPatients, klinisyenId);
      return _filterPatients(patients, aramaMetni);
    }
  }

  static Future<bool> isPatientOwnedByClinician(
    int hastaId,
    int klinisyenId,
  ) async {
    if (hastaId <= 0 || klinisyenId <= 0) return false;

    final directUrl = '$SUPABASE_URL/hastalar'
        '?select=hastaId'
        '&hastaId=eq.$hastaId'
        '&klinisyenId=eq.$klinisyenId'
        '&limit=1';
    final directResponse = await http
        .get(Uri.parse(directUrl), headers: _headers())
        .timeout(const Duration(seconds: 5));
    if (directResponse.statusCode == 200) {
      final List<dynamic> direct = json.decode(directResponse.body);
      if (direct.isNotEmpty) return true;
    } else {
      throw Exception(
        'Hasta sahipliği kontrol edilemedi. Kod: ${directResponse.statusCode}',
      );
    }

    final legacyUrl = '$SUPABASE_URL/degerlendirmeler'
        '?select=hastaId'
        '&hastaId=eq.$hastaId'
        '&klinisyenId=eq.$klinisyenId'
        '&limit=1';
    final legacyResponse = await http
        .get(Uri.parse(legacyUrl), headers: _headers())
        .timeout(const Duration(seconds: 5));
    if (legacyResponse.statusCode == 200) {
      final List<dynamic> legacy = json.decode(legacyResponse.body);
      return legacy.isNotEmpty;
    }

    throw Exception(
      'Eski hasta sahipliği kontrol edilemedi. Kod: ${legacyResponse.statusCode}',
    );
  }

  static Future<List<Patient>> _fetchPatientsDetailed({int? klinisyenId}) async {
    final select = Uri.encodeComponent(
      '*, '
      'kullanicilar(ad,soyad,eposta), '
      'cinsiyetler(cinsiyetAdi), '
      'medeniDurumlar(medeniDurumAdi), '
      'egitimDurumlari(egitimDurumAdi), '
      'meslekler(meslekAdi), '
      'degerlendirmeler(hastalikId,hastaliklar(hastalikAdi),klinisyenNotlari)',
    );

    String url = '$SUPABASE_URL/hastalar?select=$select&order=hastaId.asc';
    if (klinisyenId != null) {
      url += '&klinisyenId=eq.$klinisyenId';
    }

    final response = await http
        .get(Uri.parse(url), headers: _headers())
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List<dynamic> liste = json.decode(response.body);
      return liste.map((j) {
        final map = j as Map<String, dynamic>;
        return Patient.fromJson(_flattenHasta(map));
      }).toList();
    }

    throw Exception(
      'Hastalar detaylı yüklenemedi. Kod: ${response.statusCode}',
    );
  }

  static Future<List<Patient>> _fetchPatientsBasic({int? klinisyenId}) async {
    final select = Uri.encodeComponent(
      'hastaId,kullaniciId,notlar,dogumTarihi,telefonNo,boy,kilo,'
      'kullanicilar(ad,soyad,eposta)',
    );

    String url = '$SUPABASE_URL/hastalar?select=$select&order=hastaId.asc';
    if (klinisyenId != null) {
      url += '&klinisyenId=eq.$klinisyenId';
    }

    final response = await http
        .get(Uri.parse(url), headers: _headers())
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List<dynamic> liste = json.decode(response.body);
      return liste.map((j) {
        final map = j as Map<String, dynamic>;
        return Patient.fromJson(_flattenHasta(map));
      }).toList();
    }

    throw Exception(
      'Hastalar temel yüklenemedi. Kod: ${response.statusCode}',
    );
  }

  static Future<List<Patient>> _appendLegacyPatients(
    List<Patient> patients,
    int klinisyenId,
  ) async {
    final legacyIds = await _fetchLegacyPatientIdsForClinician(klinisyenId);
    if (legacyIds.isEmpty) return patients;

    final existingIds = patients.map((patient) => patient.hastaId).toSet();
    final missingIds = legacyIds.where((id) => !existingIds.contains(id)).toList();
    if (missingIds.isEmpty) return patients;

    final legacyPatients = await _fetchPatientsBasicByIds(missingIds);
    return [...patients, ...legacyPatients]
      ..sort((a, b) => a.hastaId.compareTo(b.hastaId));
  }

  static Future<List<int>> _fetchLegacyPatientIdsForClinician(
    int klinisyenId,
  ) async {
    final url = '$SUPABASE_URL/degerlendirmeler'
        '?select=hastaId'
        '&klinisyenId=eq.$klinisyenId';

    final response = await http
        .get(Uri.parse(url), headers: _headers())
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List<dynamic> liste = json.decode(response.body);
      return liste
          .map((j) => (j as Map<String, dynamic>)['hastaId'])
          .whereType<num>()
          .map((id) => id.toInt())
          .toSet()
          .toList()
        ..sort();
    }

    throw Exception(
      'Eski klinisyen-hasta eşleşmeleri yüklenemedi. Kod: ${response.statusCode}',
    );
  }

  static Future<List<Patient>> _fetchPatientsBasicByIds(List<int> hastaIds) async {
    if (hastaIds.isEmpty) return [];

    final select = Uri.encodeComponent(
      'hastaId,kullaniciId,notlar,dogumTarihi,telefonNo,boy,kilo,'
      'kullanicilar(ad,soyad,eposta)',
    );
    final ids = hastaIds.join(',');
    final url = '$SUPABASE_URL/hastalar'
        '?select=$select'
        '&hastaId=in.($ids)'
        '&order=hastaId.asc';

    final response = await http
        .get(Uri.parse(url), headers: _headers())
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List<dynamic> liste = json.decode(response.body);
      return liste.map((j) {
        final map = j as Map<String, dynamic>;
        return Patient.fromJson(_flattenHasta(map));
      }).toList();
    }

    throw Exception(
      'Eski hastalar yüklenemedi. Kod: ${response.statusCode}',
    );
  }

  static List<Patient> _filterPatients(List<Patient> patients, String? aramaMetni) {
    final q = aramaMetni?.trim().toLowerCase() ?? '';
    if (q.isEmpty) return patients;

    return patients.where((h) {
      final email = (h.eposta ?? '').toLowerCase();
      return h.tamAd.toLowerCase().contains(q) ||
          email.contains(q) ||
          h.hastaId.toString().contains(q);
    }).toList();
  }

  /// Tek hasta detayı
  static Future<Patient> getHastaById(int hastaId, {int? klinisyenId}) async {
    try {
      if (klinisyenId != null &&
          !await isPatientOwnedByClinician(hastaId, klinisyenId)) {
        throw Exception('Hasta bu klinisyene atanmış değil.');
      }

      final select = Uri.encodeComponent(
        '*, '
        'kullanicilar(ad,soyad,eposta), '
        'cinsiyetler(cinsiyetAdi), '
        'medeniDurumlar(medeniDurumAdi), '
        'egitimDurumlari(egitimDurumAdi), '
        'meslekler(meslekAdi), '
        'degerlendirmeler(klinisyenId,hastalikId,hastaliklar(hastalikAdi),klinisyenNotlari)',
      );
      var url = '$SUPABASE_URL/hastalar?select=$select&hastaId=eq.$hastaId';
      if (klinisyenId != null) {
        url += '&degerlendirmeler.klinisyenId=eq.$klinisyenId';
      }

      final response = await http
          .get(Uri.parse(url), headers: _headers())
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> liste = json.decode(response.body);
        if (liste.isEmpty) throw Exception('Hasta bulunamadı.');
        return Patient.fromJson(
            _flattenHasta(liste.first as Map<String, dynamic>));
      }

      final basicList = await _fetchPatientsBasic(klinisyenId: klinisyenId);
      final matches = basicList.where((p) => p.hastaId == hastaId).toList();
      if (matches.isNotEmpty) return matches.first;

      throw Exception('Hasta bulunamadı.');
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  /// Hasta bilgilerini güncelle (boy, kilo, klinisyenNotlari vb.)
  static Future<bool> hastaGuncelle(
      int hastaId, Map<String, dynamic> data) async {
    try {
      final hastaData = <String, dynamic>{};
      if (data.containsKey('boy')) hastaData['boy'] = data['boy'];
      if (data.containsKey('kilo')) hastaData['kilo'] = data['kilo'];

      if (hastaData.isNotEmpty) {
        final response = await http.patch(
          Uri.parse('$SUPABASE_URL/hastalar?hastaId=eq.$hastaId'),
          headers: _headers(write: true),
          body: json.encode(hastaData),
        );
        if (response.statusCode != 200 && response.statusCode != 204) {
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
