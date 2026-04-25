//Sıla Özer
// lib/models/agenda_item.dart

// Bir hastanın takvim görünümündeki tek bir program öğesi.

class AgendaItem {
  final int toplantiId;
  final int hastaId;
  final int dayIndex;           // Haftanın günü (0=Pazartesi … 6=Pazar)
  final String saat;            //  "HH:mm" formatı
  final String baslik;
  final String durum;           // ("Planlandı", "Beklemede" vb.)
  final String kategori;
  final String aciklama;
  bool tamamlandiMi;

  AgendaItem({
    required this.toplantiId,
    required this.hastaId,
    required this.dayIndex,
    required this.saat,
    required this.baslik,
    required this.durum,
    required this.kategori,
    required this.aciklama,
    this.tamamlandiMi = false,
  });


  factory AgendaItem.fromMap(Map<String, dynamic> map) {
    final rawDate = map['baslangicZamani'];
    final DateTime baslangic = rawDate is DateTime
        ? rawDate
        : DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now();

    final int dayIndex = baslangic.weekday - 1;

    return AgendaItem(
      toplantiId: map['toplantiId'] ?? 0,
      hastaId: map['hastaId'] ?? 0,
      dayIndex: dayIndex,
      saat: "${baslangic.hour.toString().padLeft(2, '0')}:${baslangic.minute.toString().padLeft(2, '0')}",
      baslik: map['baslik'] ?? 'Toplantı',
      durum: map['durum'] ?? 'Planlandı',
      kategori: map['kategori'] ?? 'Randevu',
      aciklama: map['notlar'] ?? '',
      tamamlandiMi: map['tamamlandiMi'] ?? false,
    );
  }
}