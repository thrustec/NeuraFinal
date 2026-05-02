class ComparisonReport {
  final int id;
  final int hastaId;
  final String hastaAdi;
  final String baslangicTarihi;
  final String bitisTarihi;
  final DateTime olusturmaTarihi;
  final String raporBasligi;
  final String durum;

  ComparisonReport({
    required this.id,
    required this.hastaId,
    required this.hastaAdi,
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.olusturmaTarihi,
    required this.raporBasligi,
    this.durum = 'Oluşturuldu',
  });
}