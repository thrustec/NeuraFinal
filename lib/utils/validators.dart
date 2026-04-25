class PatientValidators {
  static String? validateStep1({
    required String patientEmail,
  }) {
    if (patientEmail.trim().isEmpty) {
      return 'Lütfen kayıtlı hasta kullanıcısını seçin.';
    }

    if (!patientEmail.contains('@')) {
      return 'Geçerli bir e-posta adresi girin.';
    }

    return null;
  }

  static String? validateStep2({
    required String name,
    required String surname,
    required String? gender,
    required String birthDate,
    required String phone,
    required String city,
    required String? dominantSide,
    required String empeticaId,
  }) {
    if (name.trim().isEmpty) {
      return 'Ad alanı zorunludur.';
    }
    if (surname.trim().isEmpty) {
      return 'Soyad alanı zorunludur.';
    }
    if (gender == null || gender.trim().isEmpty) {
      return 'Cinsiyet seçimi zorunludur.';
    }
    if (birthDate.trim().isEmpty) {
      return 'Doğum tarihi zorunludur.';
    }
    if (phone.trim().isEmpty) {
      return 'Telefon numarası zorunludur.';
    }
    if (city.trim().isEmpty) {
      return 'Yaşadığı yer zorunludur.';
    }
    if (dominantSide == null || dominantSide.trim().isEmpty) {
      return 'Dominant taraf seçimi zorunludur.';
    }
    if (empeticaId.trim().isEmpty) {
      return 'Empetica ID zorunludur.';
    }

    return null;
  }

  static String? validateStep3({
    required String height,
    required String weight,
  }) {
    if (height.trim().isEmpty) {
      return 'Boy alanı zorunludur.';
    }
    if (weight.trim().isEmpty) {
      return 'Kilo alanı zorunludur.';
    }

    return null;
  }
}