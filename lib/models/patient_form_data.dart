class PatientFormData {
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
}