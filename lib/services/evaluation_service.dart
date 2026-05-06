// lib/services/evaluation_service.dart

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
  // Sayı girilirse hastaId ile arar.
  // Metin girilirse kullanicilar.ad veya kullanicilar.soyad ile arar.
  // ---------------------------------------------------------------------------
  Future<List<Patient>> searchPatients(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final q = query.trim();
      final encodedQ = Uri.encodeQueryComponent(q);
      final isNumeric = RegExp(r'^\d+$').hasMatch(q);

      final taniByHastaId = <int, String>{};
      final allPatientsData = <dynamic>[];

      if (isNumeric) {
        final path = '${ApiConstants.hastalar}'
            '?select=hastaId,kullaniciId,'
            'kullanicilar(ad,soyad,eposta,aktifMi)'
            '&hastaId=eq.$encodedQ'
            '&limit=10';

        final data = await _client.get(path);
        allPatientsData.addAll(data);
      } else {
        // 1) AD / SOYAD ARAMASI
        final usersPath = '${ApiConstants.kullanicilar}'
            '?select=kullaniciId'
            '&or=(ad.ilike.*$encodedQ*,soyad.ilike.*$encodedQ*)'
            '&limit=10';

        final usersData = await _client.get(usersPath);

        final userIds = usersData
            .map((item) => (item as Map<String, dynamic>)['kullaniciId'])
            .where((id) => id != null)
            .map((id) => id.toString())
            .toList();

        if (userIds.isNotEmpty) {
          final userIdsText = userIds.join(',');

          final patientsByUserPath = '${ApiConstants.hastalar}'
              '?select=hastaId,kullaniciId,'
              'kullanicilar(ad,soyad,eposta,aktifMi)'
              '&kullaniciId=in.($userIdsText)'
              '&limit=10';

          final patientsByUserData = await _client.get(patientsByUserPath);
          allPatientsData.addAll(patientsByUserData);
        }

        // 2) TANI ARAMASI
        final diseasePath = '${ApiConstants.hastaliklar}'
            '?select=hastalikId,hastalikAdi'
            '&hastalikAdi=ilike.*$encodedQ*'
            '&limit=10';

        final diseaseData = await _client.get(diseasePath);

        final diseaseIds = <String>[];
        final diseaseNameById = <int, String>{};

        for (final item in diseaseData) {
          final map = item as Map<String, dynamic>;
          final id = map['hastalikId'];
          final name = (map['hastalikAdi'] ?? '').toString().trim();

          if (id == null || name.isEmpty) continue;

          final parsedId = int.tryParse(id.toString());
          if (parsedId == null) continue;

          diseaseIds.add(parsedId.toString());
          diseaseNameById[parsedId] = name;
        }

        if (diseaseIds.isNotEmpty) {
          final diseaseIdsText = diseaseIds.join(',');

          final evalPath = '${ApiConstants.degerlendirmeler}'
              '?select=hastaId,hastalikId'
              '&hastalikId=in.($diseaseIdsText)'
              '&order=degerlendirmeTarihi.desc';

          final evalData = await _client.get(evalPath);

          final hastaIdsFromDisease = <String>{};

          for (final item in evalData) {
            final map = item as Map<String, dynamic>;

            final hastaId = int.tryParse(map['hastaId'].toString());
            final hastalikId = int.tryParse(map['hastalikId'].toString());

            if (hastaId == null || hastalikId == null) continue;

            hastaIdsFromDisease.add(hastaId.toString());

            if (diseaseNameById.containsKey(hastalikId)) {
              taniByHastaId[hastaId] = diseaseNameById[hastalikId]!;
            }
          }

          if (hastaIdsFromDisease.isNotEmpty) {
            final hastaIdsText = hastaIdsFromDisease.join(',');

            final patientsByDiseasePath = '${ApiConstants.hastalar}'
                '?select=hastaId,kullaniciId,'
                'kullanicilar(ad,soyad,eposta,aktifMi)'
                '&hastaId=in.($hastaIdsText)'
                '&limit=10';

            final patientsByDiseaseData =
            await _client.get(patientsByDiseasePath);

            allPatientsData.addAll(patientsByDiseaseData);
          }
        }
      }

      if (allPatientsData.isEmpty) return [];

      // Aynı hasta iki kere gelmesin
      final seen = <int>{};
      final uniquePatientsData = allPatientsData.where((item) {
        final map = item as Map<String, dynamic>;
        final id = map['hastaId'] as int?;

        if (id == null) return false;
        if (seen.contains(id)) return false;

        seen.add(id);
        return true;
      }).toList();

      // İsim veya ID ile bulunan hastalar için de tanı bilgisini doldur
      final hastaIds = uniquePatientsData
          .map((item) => (item as Map<String, dynamic>)['hastaId'])
          .where((id) => id != null)
          .map((id) => id.toString())
          .toList();

      if (hastaIds.isNotEmpty) {
        final hastaIdsText = hastaIds.join(',');

        final diagnosisPath = '${ApiConstants.degerlendirmeler}'
            '?select=hastaId,hastalikId,hastaliklar(hastalikAdi)'
            '&hastaId=in.($hastaIdsText)'
            '&hastalikId=not.is.null'
            '&order=degerlendirmeTarihi.desc';

        final diagnosisData = await _client.get(diagnosisPath);

        for (final item in diagnosisData) {
          final map = item as Map<String, dynamic>;

          final hastaId = int.tryParse(map['hastaId'].toString());

          if (hastaId == null || taniByHastaId.containsKey(hastaId)) {
            continue;
          }

          final hastalikMap =
          map['hastaliklar'] as Map<String, dynamic>?;

          final hastalikAdi =
          (hastalikMap?['hastalikAdi'] ?? '').toString().trim();

          if (hastalikAdi.isNotEmpty) {
            taniByHastaId[hastaId] = hastalikAdi;
          }
        }
      }

      return _parsePatients(
        uniquePatientsData,
        taniByHastaId: taniByHastaId,
      );
    } catch (e) {
      debugPrint('EvaluationService.searchPatients error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Bir hastanın değerlendirmelerini getir
  // ---------------------------------------------------------------------------
  Future<List<EvaluationDate>> getEvaluationsForPatient(int hastaId) async {
    try {
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

        List<TestResult> testSonuclari = [];

        try {
          testSonuclari = await getTestSonuclari(
            degerlendirmeId: degerlendirmeId,
            hastaId: hastaId,
          );
        } catch (e) {
          debugPrint(
            'Test sonuçları alınamadı '
                '(degerlendirmeId: $degerlendirmeId): $e',
          );
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
  // Parse patient
  // ---------------------------------------------------------------------------
  List<Patient> _parsePatients(
      List<dynamic> data, {
        Map<int, String> taniByHastaId = const {},
      }) {
    return data
        .map((item) {
      final map = item as Map<String, dynamic>;
      final kullanici = map['kullanicilar'] as Map<String, dynamic>?;

      if (kullanici == null) return null;

      final hastaId = map['hastaId'] as int;
      final ad = (kullanici['ad'] ?? '').toString().trim();
      final soyad = (kullanici['soyad'] ?? '').toString().trim();

      if (ad.isEmpty && soyad.isEmpty) return null;

      return Patient(
        hastaId: hastaId,
        kullaniciId: map['kullaniciId'] as int,
        ad: ad,
        soyad: soyad,
        tani: taniByHastaId[hastaId] ?? 'Tanı Yok',
        durum: (kullanici['aktifMi'] as bool? ?? true)
            ? 'Aktif Hasta'
            : 'Pasif Hasta',
        degerlendirmeler: const [],
      );
    })
        .whereType<Patient>()
        .toList();
  }

  EvaluationDate _parseEvaluationDate(
      Map<String, dynamic> map,
      List<TestResult> testSonuclari,
      ) {
    final hastaliklarMap = map['hastaliklar'] as Map<String, dynamic>?;

    final DateTime dt = map['degerlendirmeTarihi'] is DateTime
        ? map['degerlendirmeTarihi'] as DateTime
        : DateTime.parse(map['degerlendirmeTarihi'] as String);

    final String tarih =
        "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/"
        "${dt.year}";

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
    final testlerMap = map['testler'] as Map<String, dynamic>? ?? {};

    return TestResult(
      testSonucId: map['testSonucId'] as int,
      testId: map['testId'] as int,
      testAdi: testlerMap['testAdi'] as String? ?? 'Test',
      olculenDeger: (map['olculenDeger'] as num? ?? 0).toDouble(),
      maxDeger: 100.0,
      birim: map['birim'] as String? ?? 'Puan',
      isLowerBetter: false,
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
        '${ApiConstants.kullanicilar}'
            '?select=kullaniciId,rolId,eposta'
            '&eposta=eq.$encodedEmail'
            '&rolId=eq.2'
            '&limit=1',
      );

      if (data is! List || data.isEmpty) {
        return null;
      }

      final user = data.first as Map<String, dynamic>;
      final idValue = user['kullaniciId'];

      if (idValue is int) return idValue;
      return int.tryParse(idValue?.toString() ?? '');
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
      if (klinisyenId == null || klinisyenId <= 0) {
        debugPrint(
          'EvaluationService.getAll blocked: valid klinisyenId is required. Value: $klinisyenId',
        );
        return [];
      }

      final path = '${ApiConstants.degerlendirmeler}'
          '?select=$_clinicalEvaluationSelect'
          '&klinisyenId=eq.$klinisyenId'
          '&order=degerlendirmeTarihi.desc';

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
          '${ApiConstants.degerlendirmeler}'
          '?select=$_clinicalEvaluationSelect'
          '&hastaId=eq.$hastaId'
          '&order=degerlendirmeTarihi.desc';

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
        '${ApiConstants.degerlendirmeler}'
            '?degerlendirmeId=eq.$id'
            '&select=$_clinicalEvaluationSelect',
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