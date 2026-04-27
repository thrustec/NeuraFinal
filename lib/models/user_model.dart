class UserModel {
  final String id;
  final String ad;
  final String soyad;
  final String eposta;
  final String telefon;
  final int rolId;
  final String rolAdi;
  final String token;

  // Klinisyen alanları (yalnızca klinisyenler için doludur)
  final String? unvan;
  final String? uzmanlikAlani;
  final String? kurumAdi;

  UserModel({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.eposta,
    required this.telefon,
    required this.rolId,
    required this.rolAdi,
    required this.token,
    this.unvan,
    this.uzmanlikAlani,
    this.kurumAdi,
  });

  String get fullName => '$ad $soyad'.trim();

  /// Klinisyen ise unvan + ad soyad ("Dr. Ayşe Yılmaz"), değilse fullName.
  String get displayName {
    final base = fullName;
    final u = (unvan ?? '').trim();
    if (u.isEmpty) return base;
    return '$u $base';
  }

  bool get isPatient => rolAdi.toLowerCase() == 'hasta';
  bool get isClinician => rolAdi.toLowerCase() == 'klinisyen';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      ad: json['ad'] ?? '',
      soyad: json['soyad'] ?? '',
      eposta: json['eposta'] ?? '',
      telefon: json['telefon'] ?? '',
      rolId: json['rolId'] ?? 1,
      rolAdi: json['rolAdi'] ?? 'Hasta',
      token: json['token'] ?? '',
      unvan: json['unvan'] as String?,
      uzmanlikAlani: json['uzmanlikAlani'] as String?,
      kurumAdi: json['kurumAdi'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad': ad,
      'soyad': soyad,
      'eposta': eposta,
      'telefon': telefon,
      'rolId': rolId,
      'rolAdi': rolAdi,
      'token': token,
      'unvan': unvan,
      'uzmanlikAlani': uzmanlikAlani,
      'kurumAdi': kurumAdi,
    };
  }
}
