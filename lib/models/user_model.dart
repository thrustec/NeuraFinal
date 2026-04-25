class UserModel {
  final String id;
  final String ad;
  final String soyad;
  final String eposta;
  final String telefon;
  final int rolId;
  final String rolAdi;
  final String token;

  UserModel({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.eposta,
    required this.telefon,
    required this.rolId,
    required this.rolAdi,
    required this.token,
  });

  String get fullName => '$ad $soyad'.trim();
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
    };
  }
}
