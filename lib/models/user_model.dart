class UserModel {
  final String id;
  final String ad;
  final String soyad;
  final String eposta;
  final int rolId;
  final String rolAdi;
  final String token;
  final String? unvan;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.eposta,
    required this.rolId,
    required this.rolAdi,
    required this.token,
    this.unvan,
    this.avatarUrl,
  });

  String get fullName => '$ad $soyad'.trim();

  String get displayName {
    final base = fullName;
    final u = (unvan ?? '').trim();
    if (u.isEmpty) return base;
    return '$u $base';
  }

  bool get isPatient   => rolAdi.toLowerCase() == 'hasta';
  bool get isClinician => rolAdi.toLowerCase() == 'klinisyen';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:        json['id']?.toString() ?? '',
      ad:        json['ad'] ?? '',
      soyad:     json['soyad'] ?? '',
      eposta:    json['eposta'] ?? '',
      rolId:     json['rolId'] ?? 1,
      rolAdi:    json['rolAdi'] ?? 'Hasta',
      token:     json['token'] ?? '',
      unvan:     json['unvan'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':        id,
      'ad':        ad,
      'soyad':     soyad,
      'eposta':    eposta,
      'rolId':     rolId,
      'rolAdi':    rolAdi,
      'token':     token,
      'unvan':     unvan,
      'avatarUrl': avatarUrl,
    };
  }
}