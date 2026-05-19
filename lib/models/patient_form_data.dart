class PatientFormData {
  int? hastaId;
  int? kullaniciId;

  // neura.kullanicilar
  String patientEmail;
  String name;
  String surname;
  int rolId;
  String sifreHash;
  bool aktifMi;

  // neura.hastalar
  int? genderId; // cinsiyetId
  String gender;

  String birthDate; // dogumTarihi
  String phone; // telefonNo
  String city; // adres

  int? dominantSideId; // baskinId
  String dominantSide;

  int? empaticaId;
  String empeticaId;

  double? heightValue; // boy
  double? weightValue; // kilo
  String height;
  String weight;

  int? educationId; // egitimDurumId
  String education;

  int? maritalStatusId; // medeniDurumId
  String maritalStatus;

  int? occupationId; // meslekId
  String occupation;

  // neura.degerlendirmeler
  int? smokingStatusId; // sigaraDurumId
  String smokingStatus;

  String complaintHistory; // hikaye
  String complaintDate; // baslangicTarihi

  int? diagnosisId; // hastalikId
  String diagnosis;

  String medications; // kullanilanIlaclar
  String exerciseStatus; // sporAliskanligi
  String assistiveDeviceStatus; // yardimciCihaz
  String caregiverStatus; // bakiciKisi

  String clinicianNotes; // klinisyenNotlari

  // acil durum bilgileri
  String emergencyContactName; // acilKisiAdi
  String emergencyPhone; // acilKisiTelefonu

  PatientFormData({
    this.hastaId,
    this.kullaniciId,

    this.patientEmail = '',
    this.name = '',
    this.surname = '',
    this.rolId = 2,
    this.sifreHash = '',
    this.aktifMi = true,

    this.genderId,
    this.gender = '',

    this.birthDate = '',
    this.phone = '',
    this.city = '',

    this.dominantSideId,
    this.dominantSide = '',

    this.empaticaId,
    this.empeticaId = '',

    this.heightValue,
    this.weightValue,
    this.height = '',
    this.weight = '',

    this.educationId,
    this.education = '',

    this.maritalStatusId,
    this.maritalStatus = '',

    this.occupationId,
    this.occupation = '',

    this.smokingStatusId,
    this.smokingStatus = '',

    this.complaintHistory = '',
    this.complaintDate = '',

    this.diagnosisId,
    this.diagnosis = '',

    this.medications = '',
    this.exerciseStatus = '',
    this.assistiveDeviceStatus = '',
    this.caregiverStatus = '',

    this.clinicianNotes = '',

    this.emergencyContactName = '',
    this.emergencyPhone = '',
  });

  PatientFormData copyWith({
    int? hastaId,
    int? kullaniciId,
    String? patientEmail,
    String? name,
    String? surname,
    int? rolId,
    String? sifreHash,
    bool? aktifMi,
    int? genderId,
    String? gender,
    String? birthDate,
    String? phone,
    String? city,
    int? dominantSideId,
    String? dominantSide,
    int? empaticaId,
    String? empeticaId,
    double? heightValue,
    double? weightValue,
    String? height,
    String? weight,
    int? educationId,
    String? education,
    int? maritalStatusId,
    String? maritalStatus,
    int? occupationId,
    String? occupation,
    int? smokingStatusId,
    String? smokingStatus,
    String? complaintHistory,
    String? complaintDate,
    int? diagnosisId,
    String? diagnosis,
    String? medications,
    String? exerciseStatus,
    String? assistiveDeviceStatus,
    String? caregiverStatus,
    String? clinicianNotes,
    String? emergencyContactName,
    String? emergencyPhone,
  }) {
    return PatientFormData(
      hastaId: hastaId ?? this.hastaId,
      kullaniciId: kullaniciId ?? this.kullaniciId,
      patientEmail: patientEmail ?? this.patientEmail,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      rolId: rolId ?? this.rolId,
      sifreHash: sifreHash ?? this.sifreHash,
      aktifMi: aktifMi ?? this.aktifMi,
      genderId: genderId ?? this.genderId,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      dominantSideId: dominantSideId ?? this.dominantSideId,
      dominantSide: dominantSide ?? this.dominantSide,
      empaticaId: empaticaId ?? this.empaticaId,
      empeticaId: empeticaId ?? this.empeticaId,
      heightValue: heightValue ?? this.heightValue,
      weightValue: weightValue ?? this.weightValue,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      educationId: educationId ?? this.educationId,
      education: education ?? this.education,
      maritalStatusId: maritalStatusId ?? this.maritalStatusId,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      occupationId: occupationId ?? this.occupationId,
      occupation: occupation ?? this.occupation,
      smokingStatusId: smokingStatusId ?? this.smokingStatusId,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      complaintHistory: complaintHistory ?? this.complaintHistory,
      complaintDate: complaintDate ?? this.complaintDate,
      diagnosisId: diagnosisId ?? this.diagnosisId,
      diagnosis: diagnosis ?? this.diagnosis,
      medications: medications ?? this.medications,
      exerciseStatus: exerciseStatus ?? this.exerciseStatus,
      assistiveDeviceStatus:
          assistiveDeviceStatus ?? this.assistiveDeviceStatus,
      caregiverStatus: caregiverStatus ?? this.caregiverStatus,
      clinicianNotes: clinicianNotes ?? this.clinicianNotes,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
    );
  }
}
