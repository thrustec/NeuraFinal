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
        final path =
            '${ApiConstants.hastalar}'
            '?select=hastaId,kullaniciId,'
            'kullanicilar(ad,soyad,eposta,aktifMi)'
            '&hastaId=eq.$encodedQ'
            '&limit=10';

        final data = await _client.get(path);
        allPatientsData.addAll(data);
      } else {
        // 1) AD / SOYAD ARAMASI
        final usersPath =
            '${ApiConstants.kullanicilar}'
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

          final patientsByUserPath =
              '${ApiConstants.hastalar}'
              '?select=hastaId,kullaniciId,'
              'kullanicilar(ad,soyad,eposta,aktifMi)'
              '&kullaniciId=in.($userIdsText)'
              '&limit=10';

          final patientsByUserData = await _client.get(patientsByUserPath);
          allPatientsData.addAll(patientsByUserData);
        }

        // 2) TANI ARAMASI
        final diseasePath =
            '${ApiConstants.hastaliklar}'
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

          final evalPath =
              '${ApiConstants.degerlendirmeler}'
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

            final patientsByDiseasePath =
                '${ApiConstants.hastalar}'
                '?select=hastaId,kullaniciId,'
                'kullanicilar(ad,soyad,eposta,aktifMi)'
                '&hastaId=in.($hastaIdsText)'
                '&limit=10';

            final patientsByDiseaseData = await _client.get(
              patientsByDiseasePath,
            );

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

        final diagnosisPath =
            '${ApiConstants.degerlendirmeler}'
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

          final hastalikMap = map['hastaliklar'] as Map<String, dynamic>?;

          final hastalikAdi = (hastalikMap?['hastalikAdi'] ?? '')
              .toString()
              .trim();

          if (hastalikAdi.isNotEmpty) {
            taniByHastaId[hastaId] = hastalikAdi;
          }
        }
      }

      return _parsePatients(uniquePatientsData, taniByHastaId: taniByHastaId);
    } catch (e) {
      debugPrint('EvaluationService.searchPatients error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Bir hastanın değerlendirmelerini getir
  // ---------------------------------------------------------------------------
  Future<List<EvaluationDate>> getEvaluationsForPatient({
    required int hastaId,
    required int klinisyenKullaniciId,
  }) async {
    if (klinisyenKullaniciId <= 0) return [];

    try {
      final path =
          '${ApiConstants.degerlendirmeler}'
          '?select=degerlendirmeId,hastaId,klinisyenId,degerlendirmeTarihi,'
          'notlar,hikaye,baslangicTarihi,kullanilanIlaclar,sporAliskanligi,'
          'yardimciCihaz,bakiciKisi,klinisyenNotlari,hastalikId,'
          'hastaliklar(hastalikAdi)'
          '&hastaId=eq.$hastaId'
          '&klinisyenId=eq.$klinisyenKullaniciId'
          '&order=degerlendirmeTarihi.desc';

      final data = await _client.get(path);

      final List<EvaluationDate> evaluations = [];

      for (var i = 0; i < data.length; i++) {
        final item = data[i];
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

        debugPrint(
          'getEvaluationsForPatient: degId=$degerlendirmeId '
          'DB rows=${testSonuclari.length}',
        );

        // Fallback: parse from the klinisyenNotlari text that
        // _composeFunctionalNote packs into the evaluation row.
        // Covers evaluations saved before the structured write was added,
        // and cases where the DB rejects inserts (e.g. testId NOT NULL).
        if (testSonuclari.isEmpty) {
          testSonuclari = parseTestSonuclariFromKlinisyenNotlari(
            map['klinisyenNotlari'] as String?,
          );
        }

        evaluations.add(
          _parseEvaluationDate(
            map,
            testSonuclari,
            isFirstEvaluation: i == data.length - 1,
          ),
        );
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
    final path =
        '${ApiConstants.degerlendirmeTestSonuclari}'
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
    List<TestResult> testSonuclari, {
    bool isFirstEvaluation = false,
  }) {
    final DateTime dt = map['degerlendirmeTarihi'] is DateTime
        ? map['degerlendirmeTarihi'] as DateTime
        : DateTime.parse(map['degerlendirmeTarihi'] as String);

    final String tarih =
        "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/"
        "${dt.year}";

    final String baslik = _buildEvaluationDisplayTitle(
      map,
      isFirstEvaluation: isFirstEvaluation,
    );

    return EvaluationDate(
      degerlendirmeId: map['degerlendirmeId'] as int,
      tarih: tarih,
      baslik: baslik,
      testSonuclari: testSonuclari,
    );
  }

  String _buildEvaluationDisplayTitle(
    Map<String, dynamic> map, {
    required bool isFirstEvaluation,
  }) {
    const titleKeys = [
      'raporBasligi',
      'reportTitle',
      'degerlendirmeBasligi',
      'evaluationTitle',
      'baslik',
      'title',
      'ziyaretTipi',
      'visitType',
      'degerlendirmeTipi',
      'summary',
      'ozet',
      'özet',
      'aciklama',
      'açıklama',
    ];

    for (final key in titleKeys) {
      final value = map[key]?.toString().trim() ?? '';
      if (_isCleanEvaluationTitle(value)) return value;
    }

    final notlar = map['notlar']?.toString().trim() ?? '';
    if (_isCleanEvaluationTitle(notlar)) return notlar;

    final hastaliklarMap = map['hastaliklar'] as Map<String, dynamic>?;
    final diagnosis =
        [
              hastaliklarMap?['hastalikAdi'],
              hastaliklarMap?['hastalik_adi'],
              map['hastalikAdi'],
              map['hastalik_adi'],
              map['tani'],
              map['tanı'],
              map['diagnosis'],
            ]
            .map((value) => value?.toString().trim() ?? '')
            .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    final visitLabel = isFirstEvaluation ? 'İlk değerlendirme' : 'Takip';
    if (diagnosis.isNotEmpty) return '$visitLabel - $diagnosis';
    return visitLabel;
  }

  bool _isCleanEvaluationTitle(String value) {
    final text = value.trim();
    if (text.isEmpty || text.contains('\n')) return false;
    final lower = text.toLowerCase();
    if (lower == 'semptomlar:' || lower.startsWith('semptomlar:')) {
      return false;
    }
    const symptomLabels = [
      'motor:',
      'duyusal:',
      'emosyonel:',
      'kognitif:',
      'pulmoner:',
      'diğer:',
      'diger:',
    ];
    return !symptomLabels.any(lower.startsWith);
  }

  TestResult _parseTestResult(Map<String, dynamic> map, int hastaId) {
    final testlerMap = map['testler'] as Map<String, dynamic>? ?? {};

    // testAdi: prefer the joined testler row; fall back to metrikAdi for rows
    // that were saved without a matching testler FK (e.g. from the form).
    final testAdi =
        testlerMap['testAdi'] as String? ??
        map['metrikAdi'] as String? ??
        'Test';
    final metrikAdi = map['metrikAdi'] as String?;
    final birim = map['birim'] as String? ?? 'Puan';

    return TestResult(
      testSonucId: map['testSonucId'] as int,
      testId: (map['testId'] as int?) ?? 0,
      testAdi: testAdi,
      metrikAdi: metrikAdi,
      olculenDeger: (map['olculenDeger'] as num? ?? 0).toDouble(),
      maxDeger: 100.0,
      birim: birim,
      isLowerBetter: _isLowerBetterMetric(birim: birim, metrikAdi: metrikAdi),
    );
  }

  bool _isLowerBetterMetric({required String birim, String? metrikAdi}) {
    final unit = birim.toLowerCase();
    final metric = (metrikAdi ?? '').toLowerCase();

    final isTimeUnit =
        unit.contains('saniye') ||
        unit.contains('sec') ||
        unit.contains('second');
    if (isTimeUnit) return true;

    final isTimeMetric =
        metric.contains('sec') ||
        metric.contains('süre') ||
        metric.contains('sure') ||
        metric.contains('zaman') ||
        metric.contains('timed') ||
        metric.contains('trail') ||
        metric.contains('peg') ||
        metric.contains('stroop');
    if (isTimeMetric) return true;

    return false;
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

      if (data.isEmpty) {
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
  // Disease id lookup by hastalikAdi
  // ---------------------------------------------------------------------------
  Future<int?> getHastalikIdByAdi(String hastalikAdi) async {
    final trimmed = hastalikAdi.trim();
    if (trimmed.isEmpty) return null;
    try {
      final encoded = Uri.encodeQueryComponent(trimmed);
      final data = await _client.get(
        '${ApiConstants.hastaliklar}?select=hastalikId&hastalikAdi=eq.$encoded&limit=1',
      );
      if (data.isEmpty) return null;
      final id = (data.first as Map<String, dynamic>)['hastalikId'];
      if (id is int) return id;
      return int.tryParse(id?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Test ID lookup — queries testler table once; returns lowercase-keyed map
  // so callers can do a case-insensitive match against their own label strings.
  // Returns empty map on any error so callers can proceed without testId.
  // ---------------------------------------------------------------------------
  Future<Map<String, int>> getTestIdMap() async {
    try {
      final data = await _client.get(
        '${ApiConstants.testler}?select=testId,testAdi,testKodu',
      );
      final result = <String, int>{};
      for (final item in data) {
        final m = item as Map<String, dynamic>;
        final id = m['testId'];
        if (id == null) continue;
        final parsedId = id is int ? id : int.tryParse(id.toString());
        if (parsedId == null) continue;
        final adi = (m['testAdi'] ?? '').toString().trim();
        final kodu = (m['testKodu'] ?? '').toString().trim();
        if (adi.isNotEmpty) result[adi.toLowerCase()] = parsedId;
        if (kodu.isNotEmpty) result[kodu.toLowerCase()] = parsedId;
      }
      return result;
    } catch (e) {
      debugPrint('EvaluationService.getTestIdMap error (non-fatal): $e');
      return {};
    }
  }

  Future<int?> findOrCreateTest({
    required String testAdi,
    required String testKodu,
    required String kategori,
  }) async {
    final adi = testAdi.trim();
    final kodu = testKodu.trim();
    if (adi.isEmpty && kodu.isEmpty) return null;

    try {
      final filters = <String>[];
      if (adi.isNotEmpty) {
        filters.add('testAdi.eq.${Uri.encodeQueryComponent(adi)}');
      }
      if (kodu.isNotEmpty) {
        filters.add('testKodu.eq.${Uri.encodeQueryComponent(kodu)}');
      }

      if (filters.isNotEmpty) {
        final data = await _client.get(
          '${ApiConstants.testler}'
          '?select=testId'
          '&or=(${filters.join(',')})'
          '&limit=1',
        );
        if (data.isNotEmpty) {
          return _asInt((data.first as Map<String, dynamic>)['testId']);
        }
      }

      final created = await _client.post(ApiConstants.testler, {
        'testAdi': adi.isEmpty ? kodu : adi,
        'testKodu': kodu.isEmpty ? adi : kodu,
        'kategori': kategori.trim().isEmpty ? null : kategori.trim(),
        'aktifMi': true,
      });
      final map = created is List ? created.first : created;
      return _asInt((map as Map<String, dynamic>)['testId']);
    } catch (e) {
      debugPrint('EvaluationService.findOrCreateTest error (non-fatal): $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Persist structured test rows for an evaluation.
  // Strategy: delete stale rows for (degerlendirmeId, hastaId) then insert.
  // Each insert failure is logged but does NOT abort the rest — a partial
  // save is better than losing all test data.
  // ---------------------------------------------------------------------------
  Future<void> upsertTestSonuclari({
    required int degerlendirmeId,
    required int hastaId,
    required List<Map<String, dynamic>> rows,
  }) async {
    if (rows.isEmpty) return;

    try {
      await _client.delete(
        '${ApiConstants.degerlendirmeTestSonuclari}'
        '?degerlendirmeId=eq.$degerlendirmeId'
        '&hastaId=eq.$hastaId',
      );
    } catch (e) {
      debugPrint(
        'EvaluationService.upsertTestSonuclari delete error (non-fatal): $e',
      );
    }

    for (final row in rows) {
      try {
        final payload = Map<String, dynamic>.from(row);
        var testId = _asInt(payload['testId']);
        final testAdi = (payload.remove('_testAdi') ?? '').toString();
        final testKodu = (payload.remove('_testKodu') ?? '').toString();
        final testKategori = (payload.remove('_testKategori') ?? '').toString();

        testId ??= await findOrCreateTest(
          testAdi: testAdi,
          testKodu: testKodu,
          kategori: testKategori,
        );

        if (testId == null) {
          debugPrint(
            'EvaluationService.upsertTestSonuclari skipped row without '
            'testId: $row',
          );
          continue;
        }

        payload['testId'] = testId;
        await _client.post(ApiConstants.degerlendirmeTestSonuclari, payload);
      } catch (e) {
        debugPrint(
          'EvaluationService.upsertTestSonuclari insert error (non-fatal): '
          '$e  row=$row',
        );
      }
    }
  }

  Future<int?> getExistingMuayeneIdForEvaluation({
    required int degerlendirmeId,
    required int hastaId,
  }) async {
    try {
      final data = await _client.get(
        '/demografikBilgiler'
        '?select=muayeneId'
        '&degerlendirmeId=eq.$degerlendirmeId'
        '&hastaId=eq.$hastaId'
        '&limit=1',
      );
      if (data.isEmpty) return null;
      return _asInt((data.first as Map<String, dynamic>)['muayeneId']);
    } catch (e) {
      debugPrint(
        'EvaluationService.getExistingMuayeneIdForEvaluation error '
        '(non-fatal): $e',
      );
      return null;
    }
  }

  Future<int?> createMuayene({
    required int hastaId,
    required String muayeneTarihi,
    int? degerlendirmeId,
    String? notlar,
  }) async {
    if (degerlendirmeId != null && degerlendirmeId > 0) {
      final existing = await getExistingMuayeneIdForEvaluation(
        degerlendirmeId: degerlendirmeId,
        hastaId: hastaId,
      );
      if (existing != null) {
        await _patchByFilter('/muayeneler', 'muayeneId=eq.$existing', {
          'hastaId': hastaId,
          'muayeneTarihi': muayeneTarihi,
          'notlar': notlar,
        });
        return existing;
      }
    }

    final data = await _client.post('/muayeneler', {
      'hastaId': hastaId,
      'muayeneTarihi': muayeneTarihi,
      'notlar': notlar,
    });
    final map = data is List ? data.first : data;
    return _asInt((map as Map<String, dynamic>)['muayeneId']);
  }

  Future<int?> getOrCreateKlinikDegerlendirme({
    required int hastaId,
    required int muayeneId,
    String? notlar,
  }) async {
    final existing = await _client.get(
      '/klinikDegerlendirmeler'
      '?select=klinikDegerlendirmeId'
      '&hastaId=eq.$hastaId'
      '&muayeneId=eq.$muayeneId'
      '&limit=1',
    );
    if (existing.isNotEmpty) {
      final id = _asInt(
        (existing.first as Map<String, dynamic>)['klinikDegerlendirmeId'],
      );
      if (id != null) {
        await _patchByFilter(
          '/klinikDegerlendirmeler',
          'klinikDegerlendirmeId=eq.$id',
          {'hastaId': hastaId, 'muayeneId': muayeneId, 'notlar': notlar},
        );
      }
      return id;
    }

    final data = await _client.post('/klinikDegerlendirmeler', {
      'hastaId': hastaId,
      'muayeneId': muayeneId,
      'notlar': notlar,
    });
    final map = data is List ? data.first : data;
    return _asInt((map as Map<String, dynamic>)['klinikDegerlendirmeId']);
  }

  Future<int?> getOrCreateDemografikBilgiler({
    required int degerlendirmeId,
    required int hastaId,
    required int muayeneId,
  }) async {
    final existing = await _client.get(
      '/demografikBilgiler'
      '?select=demografikBilgiId'
      '&degerlendirmeId=eq.$degerlendirmeId'
      '&hastaId=eq.$hastaId'
      '&limit=1',
    );
    if (existing.isNotEmpty) {
      final id = _asInt(
        (existing.first as Map<String, dynamic>)['demografikBilgiId'],
      );
      if (id != null) {
        await _patchByFilter(
          '/demografikBilgiler',
          'demografikBilgiId=eq.$id',
          {
            'degerlendirmeId': degerlendirmeId,
            'hastaId': hastaId,
            'muayeneId': muayeneId,
          },
        );
      }
      return id;
    }

    final data = await _client.post('/demografikBilgiler', {
      'degerlendirmeId': degerlendirmeId,
      'hastaId': hastaId,
      'muayeneId': muayeneId,
    });
    final map = data is List ? data.first : data;
    return _asInt((map as Map<String, dynamic>)['demografikBilgiId']);
  }

  Future<int?> findOrCreateBelirti({
    required String belirtiAdi,
    String? kategoriAdi,
  }) async {
    final name = belirtiAdi.trim();
    if (name.isEmpty) return null;

    final encodedName = Uri.encodeQueryComponent(name);
    final existing = await _client.get(
      '/belirtiler'
      '?select=belirtiId'
      '&belirtiAdi=eq.$encodedName'
      '&limit=1',
    );
    if (existing.isNotEmpty) {
      return _asInt((existing.first as Map<String, dynamic>)['belirtiId']);
    }

    final kategoriId = await _findOrCreateBelirtiKategori(kategoriAdi);
    final body = <String, dynamic>{
      'belirtiAdi': name,
      ...?(kategoriId == null ? null : {'kategoriId': kategoriId}),
    };
    final data = await _client.post('/belirtiler', body);
    final map = data is List ? data.first : data;
    return _asInt((map as Map<String, dynamic>)['belirtiId']);
  }

  Future<void> saveMuayeneBelirtileri({
    required int muayeneId,
    required List<Map<String, dynamic>> belirtiler,
    int? hastalikId,
  }) async {
    try {
      await _client.delete('/muayeneBelirtileri?muayeneId=eq.$muayeneId');
    } catch (e) {
      debugPrint(
        'EvaluationService.saveMuayeneBelirtileri delete error '
        '(non-fatal): $e',
      );
    }

    final seen = <String>{};
    for (final item in belirtiler) {
      final belirtiAdi = (item['belirtiAdi'] ?? '').toString().trim();
      final kategoriAdi = (item['kategoriAdi'] ?? '').toString().trim();
      final rowHastalikAdi = (item['hastalikAdi'] ?? '').toString().trim();
      final notlar = (item['notlar'] ?? '').toString().trim();
      if (belirtiAdi.isEmpty) continue;

      final key =
          '${kategoriAdi.toLowerCase()}|'
          '${rowHastalikAdi.toLowerCase()}|'
          '${belirtiAdi.toLowerCase()}';
      if (!seen.add(key)) continue;

      try {
        final belirtiId = await findOrCreateBelirti(
          belirtiAdi: belirtiAdi,
          kategoriAdi: kategoriAdi.isEmpty ? null : kategoriAdi,
        );
        if (belirtiId == null) continue;

        final relatedHastalikId = rowHastalikAdi.isEmpty
            ? hastalikId
            : (await getHastalikIdByAdi(rowHastalikAdi)) ?? hastalikId;

        if (relatedHastalikId != null) {
          await _getOrCreateBelirtiVerisi(
            hastalikId: relatedHastalikId,
            belirtiId: belirtiId,
          );
        }

        await _client.post('/muayeneBelirtileri', {
          'muayeneId': muayeneId,
          'belirtiId': belirtiId,
          'siddet': null,
          'notlar': notlar.isEmpty ? null : notlar,
        });
      } catch (e) {
        debugPrint(
          'EvaluationService.saveMuayeneBelirtileri insert error '
          '(non-fatal): $e item=$item',
        );
      }
    }
  }

  Future<void> saveFunctionalStructuredRows({
    required int muayeneId,
    required Map<String, Map<String, dynamic>> rowsByTable,
  }) async {
    for (final entry in rowsByTable.entries) {
      final table = entry.key;
      final primaryKey = _functionalPrimaryKeyByTable[table];
      final row = Map<String, dynamic>.from(entry.value)
        ..['muayeneId'] = muayeneId;

      if (row.length <= 1) continue;

      try {
        final existing = await _client.get(
          '/$table?select=${primaryKey ?? 'muayeneId'}'
          '&muayeneId=eq.$muayeneId'
          '&limit=1',
        );
        if (existing.isEmpty) {
          await _client.post('/$table', row);
        } else {
          final id = primaryKey == null
              ? null
              : _asInt((existing.first as Map<String, dynamic>)[primaryKey]);
          final filter = id == null
              ? 'muayeneId=eq.$muayeneId'
              : '$primaryKey=eq.$id';
          await _patchByFilter('/$table', filter, row);
        }
      } catch (e) {
        debugPrint(
          'EvaluationService.saveFunctionalStructuredRows $table error '
          '(non-fatal): $e row=$row',
        );
      }
    }
  }

  static const Map<String, String> _functionalPrimaryKeyByTable = {
    'fonksiyonelGenel': 'fonksiyonelGenelId',
    'fonksiyonelCtsib': 'fonksiyonelCtsibId',
    'fonksiyonelPst': 'fonksiyonelPstId',
    'fonksiyonelIzKosu': 'fonksiyonelIzKosuId',
    'fonksiyonelStroop': 'fonksiyonelStroopId',
  };

  Future<int?> _findOrCreateBelirtiKategori(String? kategoriAdi) async {
    final name = (kategoriAdi ?? '').trim();
    if (name.isEmpty) return null;

    final encodedName = Uri.encodeQueryComponent(name);
    final existing = await _client.get(
      '/belirtiKategorileri'
      '?select=kategoriId'
      '&kategoriAdi=eq.$encodedName'
      '&limit=1',
    );
    if (existing.isNotEmpty) {
      return _asInt((existing.first as Map<String, dynamic>)['kategoriId']);
    }

    final data = await _client.post('/belirtiKategorileri', {
      'kategoriAdi': name,
    });
    final map = data is List ? data.first : data;
    return _asInt((map as Map<String, dynamic>)['kategoriId']);
  }

  Future<int?> _getOrCreateBelirtiVerisi({
    required int hastalikId,
    required int belirtiId,
  }) async {
    try {
      final existing = await _client.get(
        '/belirtiVerileri'
        '?select=belirtiVeriId'
        '&hastalikId=eq.$hastalikId'
        '&belirtiId=eq.$belirtiId'
        '&limit=1',
      );
      if (existing.isNotEmpty) {
        return _asInt(
          (existing.first as Map<String, dynamic>)['belirtiVeriId'],
        );
      }

      final data = await _client.post('/belirtiVerileri', {
        'hastalikId': hastalikId,
        'belirtiId': belirtiId,
      });
      final map = data is List ? data.first : data;
      return _asInt((map as Map<String, dynamic>)['belirtiVeriId']);
    } catch (e) {
      debugPrint(
        'EvaluationService._getOrCreateBelirtiVerisi error (non-fatal): $e',
      );
      return null;
    }
  }

  Future<void> _patchByFilter(
    String table,
    String filter,
    Map<String, dynamic> body,
  ) async {
    await _client.patch('$table?$filter', body);
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  // ---------------------------------------------------------------------------
  // Text-based test score parser — fallback when degerlendirmeTestSonuclari
  // has no rows (e.g. testId NOT NULL blocks inserts, or pre-fix evaluations).
  // Parses the inline "Label: value" lines written by _composeFunctionalNote.
  // Public so EvaluationListScreen can also call it with ev.klinisyenNotlari.
  // ---------------------------------------------------------------------------
  List<TestResult> parseTestSonuclariFromKlinisyenNotlari(String? text) {
    if (text == null || text.trim().isEmpty) return const [];

    final results = <TestResult>[];

    void extract(String label, String birim, bool isLowerBetter) {
      final raw = _extractTextValue(text, label);
      if (raw.isEmpty) return;
      final v = double.tryParse(raw.replaceAll(',', '.'));
      if (v == null) return;
      results.add(
        TestResult(
          testSonucId: label.hashCode.abs(),
          testId: 0,
          testAdi: label,
          metrikAdi: label,
          olculenDeger: v,
          maxDeger: 100.0,
          birim: birim,
          isLowerBetter: isLowerBetter,
        ),
      );
    }

    extract('Mini Mental Test Score', 'Puan', false);
    extract('UPDRS Engine Score', 'Puan', false);
    extract('ALSFRS-R Score', 'Puan', false);
    extract('Total Number of Attacks', 'Atak', false);
    extract('SARA Score', 'Puan', false);
    extract('30-sec Chair Stand Test (Reps)', 'Tekrar', false);
    extract('Timed Up & Go Test (Sec)', 'Saniye', true);
    extract('9-Hole Peg – Right Hand (Sec)', 'Saniye', true);
    extract('9-Hole Peg – Left Hand (Sec)', 'Saniye', true);
    extract('Eyes Open – Firm Surface (Sec)', 'Saniye', false);
    extract('Eyes Closed – Firm Surface (Sec)', 'Saniye', false);
    extract('Eyes Open – Soft Surface (Sec)', 'Saniye', false);
    extract('Eyes Closed – Soft Surface (Sec)', 'Saniye', false);
    extract('Anterior – Posterior', 'mm', false);
    extract('Medial – Lateral', 'mm', false);
    extract('Overall Score', 'Puan', false);
    extract('Part A (Sec)', 'Saniye', true);
    extract('Part B (Sec)', 'Saniye', true);
    extract('Stroop', 'Saniye', true);

    debugPrint(
      'parseTestSonuclariFromKlinisyenNotlari: '
      'found ${results.length} tests from text',
    );
    return results;
  }

  String _extractTextValue(String source, String label) {
    final pattern = RegExp(
      '^${RegExp.escape(label)}\\s*:[ \\t]*(.*)\$',
      caseSensitive: false,
      multiLine: true,
    );
    final match = pattern.firstMatch(source);
    return match != null ? (match.group(1) ?? '').trim() : '';
  }

  // ---------------------------------------------------------------------------
  // Clinical Evaluation module methods
  // ---------------------------------------------------------------------------
  String get _clinicalEvaluationSelect =>
      'degerlendirmeId,hastaId,klinisyenId,sigaraDurumId,'
      'degerlendirmeTarihi,notlar,hikaye,baslangicTarihi,kullanilanIlaclar,'
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

      final path =
          '${ApiConstants.degerlendirmeler}'
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

  // ---------------------------------------------------------------------------
  // Safe cascading delete — removes child rows before the main row to avoid
  // FK violations. Non-critical child deletes are logged but do not abort.
  // ---------------------------------------------------------------------------
  Future<void> delete(int id) async {
    debugPrint('EvaluationService.deleteEvaluationSafe: start id=$id');

    // Step 1: resolve muayeneId via demografikBilgiler bridge
    int? muayeneId;
    try {
      final rows = await _client.get(
        '/demografikBilgiler?select=muayeneId&degerlendirmeId=eq.$id&limit=1',
      );
      if (rows.isNotEmpty) {
        muayeneId = _asInt(
          (rows.first as Map<String, dynamic>)['muayeneId'],
        );
      }
    } catch (e) {
      debugPrint(
        'EvaluationService.deleteEvaluationSafe: muayeneId lookup (non-fatal): $e',
      );
    }

    // Step 2: delete direct degerlendirmeId child rows
    await _safeDeleteRows(
      '/degerlendirmeTestSonuclari?degerlendirmeId=eq.$id',
      'degerlendirmeTestSonuclari',
    );
    await _safeDeleteRows(
      '/degerlendirmeTestleri?degerlendirmeId=eq.$id',
      'degerlendirmeTestleri',
    );
    await _safeDeleteRows(
      '/degerlendirmePdtSonuclari?degerlendirmeId=eq.$id',
      'degerlendirmePdtSonuclari',
    );
    await _safeDeleteRows(
      '/muayenePdtDegerlendirmesi?degerlendirmeId=eq.$id',
      'muayenePdtDegerlendirmesi',
    );
    await _safeDeleteRows(
      '/bildirimler?degerlendirmeId=eq.$id',
      'bildirimler',
    );

    // Step 3: nullify rehabilitasyonProgramlari.degerlendirmeId (nullable FK)
    try {
      await _patchByFilter(
        '/rehabilitasyonProgramlari',
        'degerlendirmeId=eq.$id',
        {'degerlendirmeId': null},
      );
      debugPrint(
        'EvaluationService.deleteEvaluationSafe: nullified rehabilitasyonProgramlari.degerlendirmeId',
      );
    } catch (e) {
      debugPrint(
        'EvaluationService.deleteEvaluationSafe: rehabilitasyonProgramlari patch (non-fatal): $e',
      );
    }

    // Step 4: delete demografikBilgiler (bridges degerlendirmeId ↔ muayeneId)
    debugPrint(
      'EvaluationService.deleteEvaluationSafe: deleting demografikBilgiler...',
    );
    await _safeDeleteRows(
      '/demografikBilgiler?degerlendirmeId=eq.$id',
      'demografikBilgiler',
    );

    // Step 5: delete muayene-linked children if muayeneId found
    if (muayeneId != null) {
      await _safeDeleteRows(
        '/muayeneBelirtileri?muayeneId=eq.$muayeneId',
        'muayeneBelirtileri',
      );
      await _safeDeleteRows(
        '/fonksiyonelGenel?muayeneId=eq.$muayeneId',
        'fonksiyonelGenel',
      );
      await _safeDeleteRows(
        '/fonksiyonelCtsib?muayeneId=eq.$muayeneId',
        'fonksiyonelCtsib',
      );
      await _safeDeleteRows(
        '/fonksiyonelPst?muayeneId=eq.$muayeneId',
        'fonksiyonelPst',
      );
      await _safeDeleteRows(
        '/fonksiyonelIzKosu?muayeneId=eq.$muayeneId',
        'fonksiyonelIzKosu',
      );
      await _safeDeleteRows(
        '/fonksiyonelStroop?muayeneId=eq.$muayeneId',
        'fonksiyonelStroop',
      );
      await _safeDeleteRows(
        '/klinikDegerlendirmeler?muayeneId=eq.$muayeneId',
        'klinikDegerlendirmeler',
      );

      // Step 6: delete muayeneler only if no other demografikBilgiler references it
      try {
        final remaining = await _client.get(
          '/demografikBilgiler?select=muayeneId&muayeneId=eq.$muayeneId&limit=1',
        );
        if (remaining.isEmpty) {
          debugPrint(
            'EvaluationService.deleteEvaluationSafe: deleting muayeneler...',
          );
          await _safeDeleteRows(
            '/muayeneler?muayeneId=eq.$muayeneId',
            'muayeneler',
          );
        } else {
          debugPrint(
            'EvaluationService.deleteEvaluationSafe: muayeneler retained (still referenced by another demografikBilgiler)',
          );
        }
      } catch (e) {
        debugPrint(
          'EvaluationService.deleteEvaluationSafe: muayeneler check (non-fatal): $e',
        );
      }
    }

    // Step 7: delete the main evaluation row — must succeed
    debugPrint(
      'EvaluationService.deleteEvaluationSafe: deleting main evaluation...',
    );
    try {
      await _client.delete(
        '${ApiConstants.degerlendirmeler}?degerlendirmeId=eq.$id',
      );
      debugPrint(
        'EvaluationService.deleteEvaluationSafe: done id=$id',
      );
    } catch (e) {
      debugPrint(
        'EvaluationService.deleteEvaluationSafe: FAILED to delete degerlendirmeler: $e',
      );
      rethrow;
    }
  }

  Future<void> _safeDeleteRows(String path, String tableName) async {
    try {
      debugPrint(
        'EvaluationService.deleteEvaluationSafe: deleting $tableName...',
      );
      await _client.delete(path);
    } catch (e) {
      debugPrint(
        'EvaluationService.deleteEvaluationSafe: $tableName delete (non-fatal): $e',
      );
    }
  }
}
