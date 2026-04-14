/// Egzersiz videosu modeli
/// Tablo: neura.egzersizVideolari + neura.egzersizKategorileri join
class EgzersizVideo {
  final int egzersizVideoId;
  final int kategoriId;
  final int yukleyenId;
  final String baslik;
  final String? aciklama;
  final String videoUrl;
  final String? thumbnailUrl;
  final int sureSaniye;
  final bool aktifMi;
  final String? olusturmaTarihi;
  final String? guncellemeTarihi;

  // Join'den gelen kategori bilgisi
  final String? kategoriAdi;

  EgzersizVideo({
    required this.egzersizVideoId,
    required this.kategoriId,
    required this.yukleyenId,
    required this.baslik,
    this.aciklama,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.sureSaniye,
    this.aktifMi = true,
    this.olusturmaTarihi,
    this.guncellemeTarihi,
    this.kategoriAdi,
  });

  factory EgzersizVideo.fromJson(Map<String, dynamic> json) {
    // egzersizKategorileri join'ını düzleştir
    String? katAdi;
    final kat = json['egzersizKategorileri'];
    if (kat is Map<String, dynamic>) {
      katAdi = kat['kategoriAdi'];
    }

    return EgzersizVideo(
      egzersizVideoId: json['egzersizVideoId'] ?? 0,
      kategoriId:      json['kategoriId'] ?? 0,
      yukleyenId:      json['yukleyenId'] ?? 0,
      baslik:          json['baslik'] ?? '',
      aciklama:        json['aciklama'],
      videoUrl:        json['videoUrl'] ?? '',
      thumbnailUrl:    json['thumbnailUrl'],
      sureSaniye:      json['sureSaniye'] ?? 0,
      aktifMi:         json['aktifMi'] ?? true,
      olusturmaTarihi: json['olusturmaTarihi'],
      guncellemeTarihi: json['guncellemeTarihi'],
      kategoriAdi:     katAdi ?? json['kategoriAdi'],
    );
  }

  /// Süreyi dakika cinsinden döner
  int get sureDakika => (sureSaniye / 60).ceil();

  /// "2 dk", "5 dk" formatında süre
  String get formatliSure {
    if (sureSaniye < 60) return '$sureSaniye sn';
    final dk = sureSaniye ~/ 60;
    final sn = sureSaniye % 60;
    if (sn == 0) return '$dk dk';
    return '$dk dk $sn sn';
  }

  /// Kategori adından kısa versiyon ("Denge Egzersizleri" → "Denge")
  String get kisaKategori {
    if (kategoriAdi == null) return 'Genel';
    return kategoriAdi!
        .replaceAll(' Egzersizleri', '')
        .replaceAll(' Egzersizler', '');
  }
}

/// Egzersiz kategorisi modeli
/// Tablo: neura.egzersizKategorileri
class EgzersizKategori {
  final int egzersizKategoriId;
  final String kategoriAdi;
  final String? aciklama;
  final bool aktifMi;

  EgzersizKategori({
    required this.egzersizKategoriId,
    required this.kategoriAdi,
    this.aciklama,
    this.aktifMi = true,
  });

  factory EgzersizKategori.fromJson(Map<String, dynamic> json) {
    return EgzersizKategori(
      egzersizKategoriId: json['egzersizKategoriId'] ?? 0,
      kategoriAdi:        json['kategoriAdi'] ?? '',
      aciklama:           json['aciklama'],
      aktifMi:            json['aktifMi'] ?? true,
    );
  }

  /// Kısa ad ("Denge Egzersizleri" → "Denge")
  String get kisaAd =>
      kategoriAdi
          .replaceAll(' Egzersizleri', '')
          .replaceAll(' Egzersizler', '');
}
