class Patient { // verilerin yapısı değişmemesi için final kullandım
  final int hastaId;
  final int kullaniciId;
  final String ad;
  final String soyad;
  final String? eposta;
  final String? cinsiyetAdi;
  final String? medeniDurumAdi;
  final String? egitimDurumAdi;
  final String? meslekAdi;
  final String? dogumTarihi;
  final String? telefonNo;
  final String? adres;
  final String? notlar;
  final double? boy;
  final double? kilo;
  final String? hastalikAdi;       // degerlendirmeler.hastalikId → hastaliklar.hastalikAdi
  final String? klinisyenNotlari;  // degerlendirmeler.klinisyenNotlari

  Patient({
    required this.hastaId,
    required this.kullaniciId,
    required this.ad,
    required this.soyad,
    this.eposta,
    this.cinsiyetAdi,
    this.medeniDurumAdi,
    this.egitimDurumAdi,
    this.meslekAdi,
    this.dogumTarihi,
    this.telefonNo,
    this.adres,
    this.notlar,
    this.boy,
    this.kilo,
    this.hastalikAdi,
    this.klinisyenNotlari,
  });

  String get tamAd => '$ad $soyad';

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      hastaId:          json['hastaId'] ?? 0,
      kullaniciId:      json['kullaniciId'] ?? 0,
      ad:               json['ad'] ?? '',
      soyad:            json['soyad'] ?? '',
      eposta:           json['eposta'],
      cinsiyetAdi:      json['cinsiyetAdi'] ?? json['cinsiyet']?['cinsiyetAdi'],
      medeniDurumAdi:   json['medeniDurumAdi'] ?? json['medeniDurum']?['medeniDurumAdi'],
      egitimDurumAdi:   json['egitimDurumAdi'] ?? json['egitimDurumu']?['egitimDurumAdi'],
      meslekAdi:        json['meslekAdi'] ?? json['meslek']?['meslekAdi'],
      dogumTarihi:      json['dogumTarihi'],
      telefonNo:        json['telefonNo'],
      adres:            json['adres'],
      notlar:           json['notlar'],
      boy:              (json['boy'] as num?)?.toDouble(),
      kilo:             (json['kilo'] as num?)?.toDouble(),
      hastalikAdi:      json['hastalikAdi'] ?? json['hastalik']?['hastalikAdi'],
      klinisyenNotlari: json['klinisyenNotlari'],
    );
  }

  Patient copyWith({ // veriler final olduğu için hastanın bazı bilgilerini güncellemek için copyWith
    String? ad,
    String? soyad,
    String? telefonNo,
    String? adres,
    String? notlar,
    double? boy,
    double? kilo,
    String? klinisyenNotlari,
  }) {
    return Patient(
      hastaId:          hastaId,
      kullaniciId:      kullaniciId,
      ad:               ad               ?? this.ad,
      soyad:            soyad            ?? this.soyad,
      eposta:           eposta,
      cinsiyetAdi:      cinsiyetAdi,
      medeniDurumAdi:   medeniDurumAdi,
      egitimDurumAdi:   egitimDurumAdi,
      meslekAdi:        meslekAdi,
      dogumTarihi:      dogumTarihi,
      telefonNo:        telefonNo        ?? this.telefonNo,
      adres:            adres            ?? this.adres,
      notlar:           notlar           ?? this.notlar,
      boy:              boy              ?? this.boy,
      kilo:             kilo             ?? this.kilo,
      hastalikAdi:      hastalikAdi,
      klinisyenNotlari: klinisyenNotlari ?? this.klinisyenNotlari,
    );
  }
}