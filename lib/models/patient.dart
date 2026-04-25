// Sıla Özer
// lib/models/patient.dart


import 'comparison_result.dart';

class Patient {
  final int hastaId;
  final int kullaniciId;
  final String ad;
  final String soyad;
  final String tani;
  final String durum;         // "Aktif Hasta" vb.
  final String? fotoUrl;      // şimdilik null
  final List<EvaluationDate> degerlendirmeler; // degerlendirmeler tablosu satırları

  Patient({
    required this.hastaId,
    required this.kullaniciId,
    required this.ad,
    required this.soyad,
    required this.tani,
    required this.durum,
    this.fotoUrl,
    required this.degerlendirmeler,
  });

  // Tam adı döner (kullanicilar.ad + kullanicilar.soyad)
  String get tamAd => "$ad $soyad";


  factory Patient.fromMap(Map<String, dynamic> map, List<EvaluationDate> degerlendirmeler) {
    return Patient(
      hastaId: map['hastaId'] as int,
      kullaniciId: map['kullaniciId'] as int,
      ad: map['ad'] as String,
      soyad: map['soyad'] as String,
      tani: map['hastalikAdi'] as String? ?? 'Tanı Yok',
      durum: (map['aktifMi'] as bool? ?? true) ? 'Aktif Hasta' : 'Pasif Hasta',
      fotoUrl: map['fotoUrl'] as String?,
      degerlendirmeler: degerlendirmeler,
    );
  }
}

class TestResult {
  final int testSonucId;
  final int testId;
  final String testAdi;
  final double olculenDeger;
  final double maxDeger;
  final String birim;
  final bool isLowerBetter;   // (normalAlt/normalUst)

  TestResult({
    required this.testSonucId,
    required this.testId,
    required this.testAdi,
    required this.olculenDeger,
    required this.maxDeger,
    required this.birim,
    this.isLowerBetter = false,
  });


  factory TestResult.fromMap(Map<String, dynamic> map) {
    return TestResult(
      testSonucId: map['testSonucId'] as int,
      testId: map['testId'] as int,
      testAdi: map['testAdi'] as String,
      olculenDeger: (map['olculenDeger'] as num).toDouble(),
      maxDeger: (map['maxDeger'] as num? ?? 100).toDouble(),
      birim: map['birim'] as String? ?? 'Puan',
      isLowerBetter: map['isLowerBetter'] as bool? ?? false,
    );
  }
}

class EvaluationDate {
  final int degerlendirmeId;
  final String tarih;
  final String baslik;
  final List<TestResult> testSonuclari;

  EvaluationDate({
    required this.degerlendirmeId,
    required this.tarih,
    required this.baslik,
    required this.testSonuclari,
  });


  factory EvaluationDate.fromMap(Map<String, dynamic> map, List<TestResult> testSonuclari) {
    final DateTime dt = map['degerlendirmeTarihi'] is DateTime
        ? map['degerlendirmeTarihi'] as DateTime
        : DateTime.parse(map['degerlendirmeTarihi'] as String);

    return EvaluationDate(
      degerlendirmeId: map['degerlendirmeId'] as int,
      tarih: "${dt.day.toString().padLeft(2, '0')}/"
          "${dt.month.toString().padLeft(2, '0')}/"
          "${dt.year}",
      baslik: map['notlar'] as String? ?? 'Değerlendirme',
      testSonuclari: testSonuclari,
    );
  }
}