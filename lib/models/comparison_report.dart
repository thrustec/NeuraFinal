class ComparisonReport {
  final int id;
  final int klinisyenId;
  final int hastaId;
  final String hastaAdi;
  final String baslangicTarihi;
  final String bitisTarihi;
  final DateTime olusturmaTarihi;
  final String raporBasligi;
  final String durum;
  final String? filePath;

  ComparisonReport({
    required this.id,
    required this.klinisyenId,
    required this.hastaId,
    required this.hastaAdi,
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.olusturmaTarihi,
    required this.raporBasligi,
    this.durum = 'Oluşturuldu',
    this.filePath,
  });

  factory ComparisonReport.fromJson(Map<String, dynamic> json) {
    return ComparisonReport(
      id: int.tryParse(json['raporId'].toString()) ?? 0,
      klinisyenId:
      int.tryParse(json['klinisyenId'].toString()) ?? 0,
      hastaId:
      int.tryParse(json['hastaId'].toString()) ?? 0,
      hastaAdi: json['hastaAdi'] ?? '',
      baslangicTarihi: json['baslangicTarihi'] ?? '',
      bitisTarihi: json['bitisTarihi'] ?? '',
      olusturmaTarihi: DateTime.parse(json['olusturmaTarihi']),
      raporBasligi: json['raporBasligi'] ?? '',
      durum: json['durum'] ?? 'Oluşturuldu',
      filePath: json['filePath'],
    );
  }
}