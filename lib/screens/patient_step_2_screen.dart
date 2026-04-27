import 'package:flutter/material.dart';
import '../models/patient_form_data.dart';
import '../utils/validators.dart';
import 'patient_step_3_screen.dart';

class PatientStep2Screen extends StatefulWidget {
  final PatientFormData formData;

  const PatientStep2Screen({
    super.key,
    required this.formData,
  });

  @override
  State<PatientStep2Screen> createState() => _PatientStep2ScreenState();
}

class _PatientStep2ScreenState extends State<PatientStep2Screen> {
  // NeuraApp Renk Paleti
  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kPrimary = Color(0xFF2563EB); // HASTA SAYFASI
  static const Color kTextDark = Color(0xFF1E293B);
  static const Color kTextGrey = Color(0xFF64748B);
  static const Color kTextHint = Color(0xFF94A3B8);
  static const Color kInputFill = Color(0xFFF1F5F9);
  static const Color kBorderColor = Color(0xFFE2E8F0);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController empeticaController = TextEditingController();

  String? selectedGender;
  String? selectedDominantSide;

  @override
  void initState() {
    super.initState();

    nameController.text = widget.formData.name;
    surnameController.text = widget.formData.surname;
    birthDateController.text = widget.formData.birthDate;
    phoneController.text = widget.formData.phone;
    cityController.text = widget.formData.city;
    empeticaController.text = widget.formData.empeticaId;

    selectedGender =
    widget.formData.gender.isEmpty ? null : widget.formData.gender;

    selectedDominantSide = widget.formData.dominantSide.isEmpty
        ? null
        : widget.formData.dominantSide;
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    birthDateController.dispose();
    phoneController.dispose();
    cityController.dispose();
    empeticaController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime initialDate = DateTime(2000, 1, 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              onSurface: kTextDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        birthDateController.text =
        "${picked.day.toString().padLeft(2, '0')}/"
            "${picked.month.toString().padLeft(2, '0')}/"
            "${picked.year}";
      });
    }
  }

  int? mapGenderToId(String? value) {
    if (value == 'Kadın') return 1;
    if (value == 'Erkek') return 2;
    return null;
  }

  int? mapDominantSideToId(String? value) {
    if (value == 'Sağ') return 1;
    if (value == 'Sol') return 2;
    if (value == 'Her ikisi') return 3;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // NeuraApp Input Style
    InputDecoration inputDecoration(String hintText, {Widget? suffixIcon}) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: kTextHint, fontSize: 14),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: kInputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
      );
    }

    // Label Style
    const labelStyle = TextStyle(
      color: kTextGrey,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );

    return Scaffold(
      backgroundColor: kBackground,
      // AppBar ve BottomNavigationBar kurallar gereği silindi (Sayfa ana menüye gömüleceği için).
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.badge_outlined,
                                color: kPrimary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DEMOGRAFİK BİLGİLER',
                                    style: TextStyle(
                                      color: kTextGrey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '2. Adım',
                                    style: TextStyle(
                                      color: kPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Kişisel Bilgiler',
                                    style: TextStyle(
                                      color: kTextDark,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: kBorderColor, height: 1),
                        const SizedBox(height: 24),

                        const Text('AD', style: labelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: kTextDark),
                          decoration: inputDecoration('Ad giriniz'),
                        ),
                        const SizedBox(height: 20),

                        const Text('SOYAD', style: labelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: surnameController,
                          style: const TextStyle(color: kTextDark),
                          decoration: inputDecoration('Soyad giriniz'),
                        ),
                        const SizedBox(height: 20),

                        const Text('CİNSİYET', style: labelStyle),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedGender,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kTextGrey),
                          decoration: inputDecoration('Cinsiyet seçiniz'),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          items: const [
                            DropdownMenuItem(value: 'Kadın', child: Text('Kadın', style: TextStyle(color: kTextDark))),
                            DropdownMenuItem(value: 'Erkek', child: Text('Erkek', style: TextStyle(color: kTextDark))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value;
                              widget.formData.genderId = mapGenderToId(value);
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        const Text('DOĞUM TARİHİ', style: labelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: birthDateController,
                          readOnly: true,
                          onTap: _selectDate,
                          style: const TextStyle(color: kTextDark),
                          decoration: inputDecoration(
                            'GG/AA/YYYY',
                            suffixIcon: const Icon(Icons.calendar_today_outlined, color: kPrimary, size: 20),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text('TELEFON NUMARASI', style: labelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: kTextDark),
                          decoration: inputDecoration('Telefon numarası giriniz'),
                        ),
                        const SizedBox(height: 20),

                        const Text('YAŞADIĞI YER', style: labelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: cityController,
                          style: const TextStyle(color: kTextDark),
                          decoration: inputDecoration('Şehir / ilçe giriniz'),
                        ),
                        const SizedBox(height: 20),

                        const Text('DOMİNANT TARAF', style: labelStyle),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedDominantSide,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kTextGrey),
                          decoration: inputDecoration('Dominant taraf seçiniz'),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          items: const [
                            DropdownMenuItem(value: 'Sağ', child: Text('Sağ', style: TextStyle(color: kTextDark))),
                            DropdownMenuItem(value: 'Sol', child: Text('Sol', style: TextStyle(color: kTextDark))),
                            DropdownMenuItem(value: 'Her ikisi', child: Text('Her ikisi', style: TextStyle(color: kTextDark))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedDominantSide = value;
                              widget.formData.dominantSideId = mapDominantSideToId(value);
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        const Text('EMPETICA ID', style: labelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: empeticaController,
                          style: const TextStyle(color: kTextDark),
                          decoration: inputDecoration('Empetica ID giriniz'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            side: const BorderSide(color: kBorderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Geri', style: TextStyle(color: kTextGrey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final error = PatientValidators.validateStep2(
                              name: nameController.text,
                              surname: surnameController.text,
                              gender: selectedGender,
                              birthDate: birthDateController.text,
                              phone: phoneController.text,
                              city: cityController.text,
                              dominantSide: selectedDominantSide,
                              empeticaId: empeticaController.text,
                            );

                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            widget.formData.name = nameController.text.trim();
                            widget.formData.surname = surnameController.text.trim();
                            widget.formData.gender = selectedGender ?? '';
                            widget.formData.genderId = mapGenderToId(selectedGender);
                            widget.formData.birthDate = birthDateController.text.trim();
                            widget.formData.phone = phoneController.text.trim();
                            widget.formData.city = cityController.text.trim();
                            widget.formData.dominantSide = selectedDominantSide ?? '';
                            widget.formData.dominantSideId = mapDominantSideToId(selectedDominantSide);
                            widget.formData.empeticaId = empeticaController.text.trim();
                            widget.formData.empaticaId = int.tryParse(empeticaController.text.trim());

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientStep3Screen(formData: widget.formData),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Devam'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(8, (index) {
                        final bool isActive = index == 1;
                        final bool isDone = index < 1;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? kPrimary : (isDone ? kPrimary.withOpacity(0.1) : Colors.white),
                            border: Border.all(
                              color: (isActive || isDone) ? kPrimary : kBorderColor,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check, size: 16, color: kPrimary)
                                : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.white : kTextHint,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}