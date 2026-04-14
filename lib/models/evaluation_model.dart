class Evaluation {
  final int degerlendirmeId;
  final int hastaId;
  final String degerlendirmeTarihi;
  final String? hastalikAdi;       // hastaliklar.hastalikAdi
  final String? notlar;            // degerlendirmeler.notlar
  final String? klinisyenNotlari;  // degerlendirmeler.klinisyenNotlari
  final String? kullanilanIlaclar;
  final String? hikaye;

  Evaluation({
    required this.degerlendirmeId,
    required this.hastaId,
    required this.degerlendirmeTarihi,
    this.hastalikAdi,
    this.notlar,
    this.klinisyenNotlari,
    this.kullanilanIlaclar,
    this.hikaye,
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    return Evaluation(
      degerlendirmeId:    json['degerlendirmeId'] ?? 0,
      hastaId:            json['hastaId'] ?? 0,
      degerlendirmeTarihi: json['degerlendirmeTarihi'] ?? '',
      hastalikAdi:        json['hastalikAdi'] ??
          json['hastalik']?['hastalikAdi'],
      notlar:             json['notlar'],
      klinisyenNotlari:   json['klinisyenNotlari'],
      kullanilanIlaclar:  json['kullanilanIlaclar'],
      hikaye:             json['hikaye'],
    );
  }

  // Tarihi okunabilir formata çevirir: "2026-03-10T00:00:00" → "10.03.2026"
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
}