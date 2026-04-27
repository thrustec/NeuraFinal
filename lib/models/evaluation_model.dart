class Evaluation {
  final int? id;
  final int degerlendirmeId;
  final int doctorId;
  final int hastaId;
  final String degerlendirmeTarihi;

  final String? hastaAdSoyad;
  final int? sigaraDurumId;
  final String? hastalikAdi;
  final String? diagnosis;
  final String? hikaye;
  final String? notlar;
  final String? klinisyenNotlari;
  final String? kullanilanIlaclar;
  final String? clinicType;
  final String? symptomsNote;
  final String? diseaseNote;
  final String? functionalsNote;
  final String? caregiver;

  final List<String> symptoms;

  Evaluation({
    this.id,
    required this.degerlendirmeId,
    required this.doctorId,
    required this.hastaId,
    required this.degerlendirmeTarihi,
    this.hastaAdSoyad,
    this.sigaraDurumId,
    this.hastalikAdi,
    this.diagnosis,
    this.hikaye,
    this.notlar,
    this.klinisyenNotlari,
    this.kullanilanIlaclar,
    this.clinicType,
    this.symptomsNote,
    this.diseaseNote,
    this.functionalsNote,
    this.caregiver,
    this.symptoms = const [],
  });

  static String _extractPackedSection(String source, String title) {
    final text = source.trim();
    if (text.isEmpty) return '';

    final header = '$title:\n';
    final start = text.lastIndexOf(header);
    if (start == -1) return '';

    final contentStart = start + header.length;
    final nextHeaders = [
      '\n\nSemptomlar:\n',
      '\n\nHastalık:\n',
      '\n\nKlinisyen Notları:\n',
      '\n\nFonksiyonel:\n',
      '\n\nKlinik tip:',
    ];

    int? end;
    for (final marker in nextHeaders) {
      final idx = text.indexOf(marker, contentStart);
      if (idx != -1 && (end == null || idx < end)) {
        end = idx;
      }
    }

    final result = end == null
        ? text.substring(contentStart)
        : text.substring(contentStart, end);
    return result.trim();
  }

  static List<String> _parseSymptomsFromNotlar(String? rawNotlar) {
    final notlar = (rawNotlar ?? '').trim();
    if (notlar.isEmpty) return const [];

    final semptomlar = _extractPackedSection(notlar, 'Semptomlar');
    if (semptomlar.isEmpty) return const [];

    const labels = [
      'Motor',
      'Duyusal',
      'Emosyonel',
      'Kognitif',
      'Pulmoner',
      'Diğer',
    ];

    const emptyValues = {
      'yok',
      'none',
      '-',
      'seçilmedi',
      'secilmedi',
      'boş',
      'bos',
    };

    final uniqueSymptoms = <String>{};

    for (final rawLine in semptomlar.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      String? matchedLabel;
      for (final label in labels) {
        if (line.toLowerCase().startsWith('${label.toLowerCase()}:')) {
          matchedLabel = label;
          break;
        }
      }
      if (matchedLabel == null) continue;

      final value = line.substring(matchedLabel.length + 1).trim();
      if (value.isEmpty) continue;

      final lower = value.toLowerCase();
      final extraIndex = lower.indexOf('yeni bulgu:');
      final selectedPart = extraIndex == -1
          ? value
          : value.substring(0, extraIndex).trim();

      if (selectedPart.isEmpty) continue;

      for (final item in selectedPart.split(',')) {
        final symptom = item.trim();
        if (symptom.isEmpty) continue;

        final normalized = symptom.toLowerCase();
        if (emptyValues.contains(normalized)) continue;
        if (normalized.startsWith('yeni bulgu:')) continue;

        uniqueSymptoms.add(symptom);
      }
    }

    return uniqueSymptoms.toList(growable: false);
  }

  static List<String> _parseSymptomsFromJson(dynamic symptomsValue) {
    if (symptomsValue is! List) return const [];

    const emptyValues = {
      'yok',
      'none',
      '-',
      'seçilmedi',
      'secilmedi',
      'boş',
      'bos',
    };

    final uniqueSymptoms = <String>{};

    for (final raw in symptomsValue) {
      final symptom = raw?.toString().trim() ?? '';
      if (symptom.isEmpty) continue;

      final normalized = symptom.toLowerCase();
      if (emptyValues.contains(normalized)) continue;
      if (normalized.startsWith('yeni bulgu:')) continue;

      uniqueSymptoms.add(symptom);
    }

    return uniqueSymptoms.toList(growable: false);
  }

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    final nestedAd = (json['hastalar']?['kullanicilar']?['ad'] ?? '')
        .toString()
        .trim();
    final nestedSoyad = (json['hastalar']?['kullanicilar']?['soyad'] ?? '')
        .toString()
        .trim();
    final nestedTamAd = [nestedAd, nestedSoyad]
        .where((e) => e.isNotEmpty)
        .join(' ')
        .trim();

    final directAd = (json['ad'] ?? '').toString().trim();
    final directSoyad = (json['soyad'] ?? '').toString().trim();
    final directTamAd = [directAd, directSoyad]
        .where((e) => e.isNotEmpty)
        .join(' ')
        .trim();

    final hastaAdSoyad = [
      json['hastaAdSoyad'],
      json['hasta_ad_soyad'],
      json['hastaTamAd'],
      json['hasta_tam_ad'],
      json['tamAd'],
      json['tam_ad'],
      json['adSoyad'],
      json['ad_soyad'],
      nestedTamAd.isNotEmpty ? nestedTamAd : null,
      directTamAd.isNotEmpty ? directTamAd : null,
      json['hastaAd'],
    ]
        .map((e) => e?.toString().trim() ?? '')
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');

    final hastalikAdi = [
      json['hastalikAdi'],
      json['hastalik_adi'],
      json['hastaliklar']?['hastalikAdi'],
      json['hastalik']?['hastalikAdi'],
      json['diagnosis'],
    ]
        .map((e) => e?.toString().trim() ?? '')
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');

    final rawNotlar = json['notlar']?.toString();
    final parsedSymptomsFromNotlar = _parseSymptomsFromNotlar(rawNotlar);
    final parsedSymptomsFromJson = _parseSymptomsFromJson(json['symptoms']);
    final resolvedSymptoms = parsedSymptomsFromNotlar.isNotEmpty
        ? parsedSymptomsFromNotlar
        : parsedSymptomsFromJson;

    return Evaluation(
      id: json['degerlendirmeId'] ?? json['id'],
      degerlendirmeId: (json['degerlendirmeId'] ?? json['id'] ?? 0) as int,
      doctorId:
      (json['klinisyenId'] ?? json['doctorId'] ?? json['doctor_id'] ?? 0)
      as int,
      hastaId: (json['hastaId'] ?? json['hasta_id'] ?? 0) as int,
      degerlendirmeTarihi:
      (json['degerlendirmeTarihi'] ?? json['degerlendirme_tarihi'] ?? '')
          .toString(),
      hastaAdSoyad: hastaAdSoyad.isEmpty ? null : hastaAdSoyad,
      sigaraDurumId: json['sigaraDurumId'] as int?,
      hastalikAdi: hastalikAdi.isEmpty ? null : hastalikAdi,
      notlar: rawNotlar,
      klinisyenNotlari: json['klinisyenNotlari']?.toString(),
      kullanilanIlaclar: json['kullanilanIlaclar']?.toString(),
      hikaye: json['hikaye']?.toString(),
      diagnosis: hastalikAdi.isEmpty ? null : hastalikAdi,
      clinicType: json['clinicType']?.toString(),
      symptomsNote: json['symptomsNote']?.toString(),
      diseaseNote: json['diseaseNote']?.toString(),
      functionalsNote: json['functionalsNote']?.toString(),
      caregiver: (json['bakiciKisi'] ?? json['caregiver'])?.toString(),
      symptoms: resolvedSymptoms,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'hastaId': hastaId,
      'klinisyenId': doctorId,
      'sigaraDurumId': sigaraDurumId,
      'degerlendirmeTarihi': degerlendirmeTarihi,
      'notlar': notlar,
      'hikaye': hikaye,
      'kullanilanIlaclar': kullanilanIlaclar,
      'bakiciKisi': caregiver,
      'klinisyenNotlari': klinisyenNotlari,
      // symptoms ayrı DB kolonu değilse ekleme. Semptomlar notlar içinde güncel olarak saklanır.
      // 'symptoms': symptoms,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'hastaId': hastaId,
      'klinisyenId': doctorId,
      'sigaraDurumId': sigaraDurumId,
      'degerlendirmeTarihi': degerlendirmeTarihi,
      'notlar': notlar,
      'hikaye': hikaye,
      'kullanilanIlaclar': kullanilanIlaclar,
      'bakiciKisi': caregiver,
      'klinisyenNotlari': klinisyenNotlari,
      // Update sırasında eski semptomlarla merge yapılmamalı; notlar alanı güncel paket olarak replace edilir.
      // 'symptoms': symptoms,
    };
  }

  String get formatliTarih {
    try {
      final d = DateTime.parse(degerlendirmeTarihi);
      return '${d.day.toString().padLeft(2, '0')}.'
          '${d.month.toString().padLeft(2, '0')}.'
          '${d.year}';
    } catch (_) {
      return degerlendirmeTarihi;
    }
  }

  DateTime? get olusturmaTarihi {
    try {
      if (degerlendirmeTarihi.trim().isEmpty) return null;
      return DateTime.parse(degerlendirmeTarihi);
    } catch (_) {
      return null;
    }
  }

  String get hastaAdSoyadDisplay {
    if (hastaAdSoyad == null || hastaAdSoyad!.trim().isEmpty) {
      return 'Bilinmeyen hasta';
    }
    return hastaAdSoyad!;
  }

  String get hastalikAdiDisplay {
    if (hastalikAdi == null || hastalikAdi!.trim().isEmpty) {
      return 'Tanı yok';
    }
    return hastalikAdi!;
  }
}

enum LoadStatus {
  idle,
  loading,
  success,
  error,
}

class Patient {
  final int id;
  final int doctorId;
  final String ad;
  final String soyad;
  final String? eposta;

  const Patient({
    required this.id,
    required this.doctorId,
    required this.ad,
    required this.soyad,
    this.eposta,
  });

  String get adSoyad => '$ad $soyad'.trim();
}

class PatientProfile {
  final int patientId;
  final String fullName;
  final String diagnosis;
  final String height;
  final String weight;
  final String birthDate;
  final String education;
  final String maritalStatus;
  final String occupation;
  final String location;
  final String medicalHistory;
  final String caregiver;
  final String dominantSide;
  final String complaintDate;
  final int? smokingId;

  const PatientProfile({
    required this.patientId,
    required this.fullName,
    required this.diagnosis,
    required this.height,
    required this.weight,
    required this.birthDate,
    required this.education,
    required this.maritalStatus,
    required this.occupation,
    required this.location,
    required this.medicalHistory,
    required this.caregiver,
    required this.dominantSide,
    required this.complaintDate,
    this.smokingId,
  });
}

class SigaraDurum {
  final int id;
  final String ad;

  const SigaraDurum({
    required this.id,
    required this.ad,
  });

  static const defaults = <SigaraDurum>[
    SigaraDurum(id: 1, ad: 'Hiç kullanmadı'),
    SigaraDurum(id: 2, ad: 'Bıraktı'),
    SigaraDurum(id: 3, ad: 'Aktif kullanıyor'),
  ];
}