// Sıla Özer
// lib/models/comparison_result.dart

// İki değerlendirme tarihi arasındaki tek bir testin karşılaştırma sonucu.

class ComparisonResult {
  final String testAdi;         // testler.testAdi
  final double baselineDeger;   // degerlendirmeTestSonuclari.olculenDeger (başlangıç)
  final double guncelDeger;     // degerlendirmeTestSonuclari.olculenDeger (güncel)
  final double maxDeger;        // testMetrikleri.maxDeger
  final String birim;           // degerlendirmeTestSonuclari.birim
  // true ise düşen skor iyidir (örn: EDSS, UPDRS Motor).
  final bool isLowerBetter;

  ComparisonResult({
    required this.testAdi,
    required this.baselineDeger,
    required this.guncelDeger,
    required this.maxDeger,
    required this.birim,
    this.isLowerBetter = false,
  });

  // Fark (pozitif = artış, negatif = azalış)
  double get fark => guncelDeger - baselineDeger;

  // isLowerBetter'a göre gerçek anlamda iyileşme var mı?
  bool get iyilesme => isLowerBetter ? fark < 0 : fark > 0;

  factory ComparisonResult.fromMap(Map<String, dynamic> map) {
    return ComparisonResult(
      testAdi: map['testAdi'] as String,
      baselineDeger: (map['baselineDeger'] as num).toDouble(),
      guncelDeger: (map['guncelDeger'] as num).toDouble(),
      maxDeger: (map['maxDeger'] as num? ?? 100).toDouble(),
      birim: map['birim'] as String? ?? 'Puan',
      isLowerBetter: map['isLowerBetter'] as bool? ?? false,
    );
  }
}