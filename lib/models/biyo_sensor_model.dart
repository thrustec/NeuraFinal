class BiyoSensorVeri {
  final int veriId;
  final int hastaId;
  final String olcumZamani;
  final double? kalpAtisHizi;   // BPM
  final double? eda;            // Electrodermal Activity (µS)
  final double? sicaklik;       // °C
  final double? ivmeX;
  final double? ivmeY;
  final double? ivmeZ;
  final double? kanOksijeni;    // SpO2 %
  final String? uykuEvresi;

  BiyoSensorVeri({
    required this.veriId,
    required this.hastaId,
    required this.olcumZamani,
    this.kalpAtisHizi,
    this.eda,
    this.sicaklik,
    this.ivmeX,
    this.ivmeY,
    this.ivmeZ,
    this.kanOksijeni,
    this.uykuEvresi,
  });

  factory BiyoSensorVeri.fromJson(Map<String, dynamic> json) {
    return BiyoSensorVeri(
      veriId:       json['veriId'] ?? 0,
      hastaId:      json['hastaId'] ?? 0,
      olcumZamani:  json['olcumZamani'] ?? '',
      kalpAtisHizi: (json['kalpAtisHizi'] as num?)?.toDouble(),
      eda:          (json['eda'] as num?)?.toDouble(),
      sicaklik:     (json['sicaklik'] as num?)?.toDouble(),
      ivmeX:        (json['ivmeX'] as num?)?.toDouble(),
      ivmeY:        (json['ivmeY'] as num?)?.toDouble(),
      ivmeZ:        (json['ivmeZ'] as num?)?.toDouble(),
      kanOksijeni:  (json['kanOksijeni'] as num?)?.toDouble(),
      uykuEvresi:   json['uykuEvresi'],
    );
  }

  // "2026-03-10T14:30:00" → "10.03.2026 14:30"
  String get formatliZaman {
    try {
      final d = DateTime.parse(olcumZamani);
      return '${d.day.toString().padLeft(2, '0')}.'
          '${d.month.toString().padLeft(2, '0')}.'
          '${d.year}  '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return olcumZamani;
    }
  }
}