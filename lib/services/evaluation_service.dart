// lib/services/evaluation_service.dart
//
// Supabase REST API üzerinden hasta ve değerlendirme verilerini çeker.
// Senin Patient, EvaluationDate, TestResult modellerine uyarlandı.

import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import '../utils/api_constants.dart';
import 'api_client.dart';
import '../models/evaluation_model.dart' hide Patient;

class EvaluationService {
  final ApiClient _client;

  EvaluationService({ApiClient? client}) : _client = client ?? ApiClient();

  // ---------------------------------------------------------------------------
  // Hasta arama
  // Supabase REST: GET /hastalar?select=...&or=(ad.ilike.*query*,soyad.ilike.*query*)
  //
  // NOT: Supabase JOIN için ayrı tablolara ihtiyaç var.
  // Kullanicilar tablosundaki ad/soyad'ı çekmek için embedded select kullanıyoruz:
  //   kullanicilar(ad, soyad, eposta, aktifMi)
  // Hastalık adını çekmek için önce degerlendirmeler'den hastalikId alınır,
  // sonra hastaliklar tablosuna bakılır.
  // ---------------------------------------------------------------------------
  Future<List<Patient>> searchPatients(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      // Supabase embedded select ile JOIN:
      // hastalar tablosu + kullanicilar JOIN
      final q = query.trim();
      final isNumeric = RegExp(r'^\d+$').hasMatch(q);

      String path;
      if (isNumeric) {
        // Sayısal sorgu → hastaId ile ara
        path = '${ApiConstants.hastalar}'
            '?select=hastaId,kullaniciId,notlar,dogumTarihi,telefonNo,boy,kilo,'
            'kullanicilar(ad,soyad,eposta,aktifMi)'
            '&hastaId=eq.$q';
      } else {
        // Metin sorgusu → kullanicilar.ad veya soyad ile ara
        // Supabase embedded filter: kullanicilar.ad.ilike
        path = '${ApiConstants.hastalar}'
            '?select=hastaId,kullaniciId,notlar,dogumTarihi,telefonNo,boy,kilo,'
            'kullanicilar(ad,soyad,eposta,aktifMi)'
            '&kullanicilar.ad=ilike.*$q*'
            '&limit=20';
      }

      final data = await _client.get(path);
      return _parsePatients(data);
    } catch (e) {
      debugPrint('EvaluationService.searchPatients error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Bir hastanın değerlendirmelerini getir
  // GET /degerlendirmeler?hastaId=eq.:hastaId&select=...
  // + her değerlendirme için test sonuçlarını getir
  // ---------------------------------------------------------------------------
  Future<List<EvaluationDate>> getEvaluationsForPatient(int hastaId) async {
    try {
      // Degerlendirmeler + hastalik adını JOIN ile çek
      final path = '${ApiConstants.degerlendirmeler}'
          '?select=degerlendirmeId,hastaId,klinisyenId,degerlendirmeTarihi,'
          'notlar,hikaye,baslangicTarihi,kullanilanIlaclar,sporAliskanligi,'
          'yardimciCihaz,bakiciKisi,klinisyenNotlari,hastalikId,'
          'hastaliklar(hastalikAdi)'
          '&hastaId=eq.$hastaId'
          '&order=degerlendirmeTarihi.desc';

      final data = await _client.get(path);

      final List<EvaluationDate> evaluations = [];

      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final degerlendirmeId = map['degerlendirmeId'] as int;

        // Her değerlendirmenin test sonuçlarını ayrıca çek
        List<TestResult> testSonuclari = [];
        try {
          testSonuclari =
          await getTestSonuclari(degerlendirmeId: degerlendirmeId, hastaId: hastaId);
        } catch (e) {
          debugPrint('Test sonuçları alınamadı (degerlendirmeId: $degerlendirmeId): $e');
        }

        evaluations.add(_parseEvaluationDate(map, testSonuclari));
      }

      return evaluations;
    } catch (e) {
      debugPrint('EvaluationService.getEvaluationsForPatient error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Bir değerlendirmenin test sonuçlarını getir
  // GET /degerlendirmeTestSonuclari?degerlendirmeId=eq.:id&select=...
  // JOIN: testler(testAdi,testKodu,kategori), testMetrikleri(maxDeger,normalAlt,normalUst)
  // ---------------------------------------------------------------------------
  Future<List<TestResult>> getTestSonuclari({
    required int degerlendirmeId,
    required int hastaId,
  }) async {
    final path = '${ApiConstants.degerlendirmeTestSonuclari}'
        '?select=testSonucId,degerlendirmeId,hastaId,testId,metrikId,metrikAdi,'
        'olculenDeger,birim,notlar,olusturmaTarihi,'
        'testler(testAdi,testKodu,kategori,sureDakika)'
        '&degerlendirmeId=eq.$degerlendirmeId'
        '&hastaId=eq.$hastaId';

    final data = await _client.get(path);

    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return _parseTestResult(map, hastaId);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // PARSE YARDIMCI FONKSİYONLARI
  // Supabase'den gelen JSON → Model
  // ---------------------------------------------------------------------------

  List<Patient> _parsePatients(List<dynamic> data) {
    return data.map((item) {
      final map = item as Map<String, dynamic>;

      // Embedded kullanicilar JOIN verisi
      final kullanici = map['kullanicilar'] as Map<String, dynamic>? ?? {};

      return Patient(
        hastaId: map['hastaId'] as int,
        kullaniciId: map['kullaniciId'] as int,
        ad: kullanici['ad'] as String? ?? '',
        soyad: kullanici['soyad'] as String? ?? '',
        tani: 'Tanı Yok', // degerlendirmeler'den ayrıca gelecek
        durum: (kullanici['aktifMi'] as bool? ?? true)
            ? 'Aktif Hasta'
            : 'Pasif Hasta',
        degerlendirmeler: [],
      );
    }).toList();
  }

  EvaluationDate _parseEvaluationDate(
      Map<String, dynamic> map, List<TestResult> testSonuclari) {
    // Embedded hastaliklar JOIN verisi
    final hastaliklarMap = map['hastaliklar'] as Map<String, dynamic>?;

    final DateTime dt = map['degerlendirmeTarihi'] is DateTime
        ? map['degerlendirmeTarihi'] as DateTime
        : DateTime.parse(map['degerlendirmeTarihi'] as String);

    final String tarih =
        "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/"
        "${dt.year}";

    // baslik için: önce notlar, yoksa hastalık adı, o da yoksa varsayılan
    final String baslik = (map['notlar'] as String?)?.isNotEmpty == true
        ? map['notlar'] as String
        : hastaliklarMap?['hastalikAdi'] as String? ?? 'Değerlendirme';

    return EvaluationDate(
      degerlendirmeId: map['degerlendirmeId'] as int,
      tarih: tarih,
      baslik: baslik,
      testSonuclari: testSonuclari,
    );
  }

  TestResult _parseTestResult(Map<String, dynamic> map, int hastaId) {
    // Embedded testler JOIN verisi
    final testlerMap = map['testler'] as Map<String, dynamic>? ?? {};

    // maxDeger: testMetrikleri'nden gelecek, şimdilik 100 varsayılan
    // İleride testMetrikleri JOIN eklenebilir
    final double maxDeger = 100.0;

    return TestResult(
      testSonucId: map['testSonucId'] as int,
      testId: map['testId'] as int,
      testAdi: testlerMap['testAdi'] as String? ?? 'Test',
      olculenDeger: (map['olculenDeger'] as num? ?? 0).toDouble(),
      maxDeger: maxDeger,
      birim: map['birim'] as String? ?? 'Puan',
      isLowerBetter: false, // testMetrikleri'nden gelecek
    );
  }

  // ---------------------------------------------------------------------------
  // Clinician id lookup by email
  // ---------------------------------------------------------------------------
  Future<int?> getClinicianIdByEmail(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return null;

    try {
      final encodedEmail = Uri.encodeQueryComponent(trimmedEmail);
      final data = await _client.get(
        '${ApiConstants.kullanicilar}?select=kullaniciId,rolId,eposta&eposta=eq.$encodedEmail&rolId=eq.1&limit=1',
      );

      if (data is List && data.isNotEmpty) {
        final user = data.first as Map<String, dynamic>;
        final idValue = user['kullaniciId'];
        if (idValue is int) return idValue;
        return int.tryParse(idValue?.toString() ?? '');
      }

      return null;
    } catch (e) {
      debugPrint('EvaluationService.getClinicianIdByEmail error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Clinical Evaluation module methods
  // ---------------------------------------------------------------------------

  String get _clinicalEvaluationSelect =>
      'degerlendirmeId,hastaId,klinisyenId,sigaraDurumId,'
          'degerlendirmeTarihi,notlar,hikaye,kullanilanIlaclar,'
          'sporAliskanligi,yardimciCihaz,bakiciKisi,klinisyenNotlari,'
          'hastalikId,hastaliklar(hastalikAdi),'
          'hastalar(hastaId,kullaniciId,kullanicilar(ad,soyad,eposta))';

  Future<List<Evaluation>> getAll({int? klinisyenId}) async {
    try {
      var path =
          '${ApiConstants.degerlendirmeler}?select=$_clinicalEvaluationSelect&order=degerlendirmeTarihi.desc';

      if (klinisyenId != null) {
        path += '&klinisyenId=eq.$klinisyenId';
      }

      final data = await _client.get(path);
      return data
          .map<Evaluation>(
            (item) => Evaluation.fromJson(item as Map<String, dynamic>),
      )
          .toList();
    } catch (e) {
      debugPrint('EvaluationService.getAll error: $e');
      rethrow;
    }
  }

  Future<List<Evaluation>> getByPatient(int hastaId) async {
    try {
      final path =
          '${ApiConstants.degerlendirmeler}?select=$_clinicalEvaluationSelect&hastaId=eq.$hastaId&order=degerlendirmeTarihi.desc';

      final data = await _client.get(path);
      return data
          .map<Evaluation>(
            (item) => Evaluation.fromJson(item as Map<String, dynamic>),
      )
          .toList();
    } catch (e) {
      debugPrint('EvaluationService.getByPatient error: $e');
      rethrow;
    }
  }

  Future<Evaluation> create(Evaluation evaluation) async {
    try {
      final data = await _client.post(
        '${ApiConstants.degerlendirmeler}?select=$_clinicalEvaluationSelect',
        evaluation.toCreateJson(),
      );

      final map = data is List ? data.first : data;
      return Evaluation.fromJson(Map<String, dynamic>.from(map));
    } catch (e) {
      debugPrint('EvaluationService.create error: $e');
      rethrow;
    }
  }

  Future<Evaluation> update(int id, Evaluation evaluation) async {
    try {
      final data = await _client.patch(
        '${ApiConstants.degerlendirmeler}?degerlendirmeId=eq.$id&select=$_clinicalEvaluationSelect',
        evaluation.toUpdateJson(),
      );

      final map = data is List ? data.first : data;
      return Evaluation.fromJson(Map<String, dynamic>.from(map));
    } catch (e) {
      debugPrint('EvaluationService.update error: $e');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _client.delete(
        '${ApiConstants.degerlendirmeler}?degerlendirmeId=eq.$id',
      );
    } catch (e) {
      debugPrint('EvaluationService.delete error: $e');
      rethrow;
    }
  }
}