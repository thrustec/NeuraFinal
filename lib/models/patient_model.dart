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
  final String? acilKisiAdi;
  final String? adres;
  final String? notlar;
  final double? boy;
  final double? kilo;
  final String? hastalikAdi;       // degerlendirmeler.hastalikId → hastaliklar.hastalikAdi
  final String? klinisyenNotlari;  // degerlendirmeler.klinisyenNotlari
  final int? sigaraDurumId;
  final String? sigaraDurumAdi;
  final int? baskinId;
  final String? baskinElAdi;
  final String? baslangicTarihi;
  final String? bakiciKisi;

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
    this.acilKisiAdi,
    this.adres,
    this.notlar,
    this.boy,
    this.kilo,
    this.hastalikAdi,
    this.klinisyenNotlari,
    this.sigaraDurumId,
    this.sigaraDurumAdi,
    this.baskinId,
    this.baskinElAdi,
    this.baslangicTarihi,
    this.bakiciKisi,
  });

  String get tamAd => '$ad $soyad';

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      hastaId:          _asInt(json['hastaId']) ?? 0,
      kullaniciId:      _asInt(json['kullaniciId']) ?? 0,
      ad:               _firstString(json, const ['ad', 'adi', 'hastaAdi']),
      soyad:            _firstString(json, const ['soyad', 'soyadi', 'hastaSoyadi']),
      eposta:           _firstNullableString(json, const ['eposta', 'email']),
      cinsiyetAdi:      _firstNullableString(json, const [
        'cinsiyetAdi',
        'cinsiyet_adi',
        'cinsiyet',
      ]),
      medeniDurumAdi:   _firstNullableString(json, const [
        'medeniDurumAdi',
        'medeni_durum_adi',
        'medeniDurum',
        'maritalStatus',
      ]),
      egitimDurumAdi:   _firstNullableString(json, const [
        'egitimDurumAdi',
        'egitim_durum_adi',
        'egitimDurumu',
        'egitim',
        'education',
      ]),
      meslekAdi:        _firstNullableString(json, const [
        'meslekAdi',
        'meslek_adi',
        'meslek',
        'occupation',
      ]),
      dogumTarihi:      _firstNullableString(json, const ['dogumTarihi', 'birthDate']),
      telefonNo:        _firstNullableString(json, const ['telefonNo', 'phone']),
      acilKisiAdi:      _firstNullableString(json, const ['acilKisiAdi', 'emergencyContactName']),
      adres:            _firstNullableString(json, const [
        'adres',
        'yasadigiYer',
        'yaşadığıYer',
        'yasadigiSehir',
        'yaşadığıŞehir',
        'ikametYeri',
        'location',
      ]),
      notlar:           _firstNullableString(json, const ['notlar', 'notes']),
      boy:              (json['boy'] as num?)?.toDouble(),
      kilo:             (json['kilo'] as num?)?.toDouble(),
      hastalikAdi:      _firstNullableString(json, const [
        'hastalikAdi',
        'hastalik_adi',
        'tani',
        'tanı',
        'diagnosis',
      ]),
      klinisyenNotlari: _firstNullableString(json, const ['klinisyenNotlari']),
      sigaraDurumId:    _asInt(json['sigaraDurumId'] ?? json['smokingId']),
      sigaraDurumAdi:   _firstNullableString(json, const [
        'sigaraDurumAdi',
        'sigara_durum_adi',
        'sigaraKullanimi',
        'sigaraKullanımı',
        'smokingStatus',
      ]),
      baskinId:         _asInt(json['baskinId'] ?? json['dominantSideId']),
      baskinElAdi:      _firstNullableString(json, const [
        'baskinElAdi',
        'elAdi',
        'dominantSide',
        'dominantTaraf',
        'dominant_taraf',
      ]),
      baslangicTarihi:  _firstNullableString(json, const [
        'baslangicTarihi',
        'ilkSikayetTarihi',
        'ilkŞikayetTarihi',
        'complaintDate',
      ]),
      bakiciKisi:       _firstNullableString(json, const [
        'bakiciKisi',
        'bakımVeren',
        'bakimVeren',
        'caregiver',
      ]),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _firstString(Map<String, dynamic> json, List<String> keys) {
    return _firstNullableString(json, keys) ?? '';
  }

  static String? _firstNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map) {
        for (final nestedKey in const [
          'ad',
          'adi',
          'adı',
          'soyad',
          'medeniDurumAdi',
          'egitimDurumAdi',
          'meslekAdi',
          'hastalikAdi',
          'sigaraDurumAdi',
          'elAdi',
          'value',
          'name',
        ]) {
          final nestedText = value[nestedKey]?.toString().trim() ?? '';
          if (nestedText.isNotEmpty) return nestedText;
        }
      }
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
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
      sigaraDurumId:    sigaraDurumId,
      sigaraDurumAdi:   sigaraDurumAdi,
      baskinId:         baskinId,
      baskinElAdi:      baskinElAdi,
      baslangicTarihi:  baslangicTarihi,
      bakiciKisi:       bakiciKisi,
    );
  }
}
