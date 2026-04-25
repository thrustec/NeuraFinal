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
    const Color primaryBlue = Color(0xFF2563EB);
    const Color background = Color(0xFFF5F7FB);
    const Color cardColor = Colors.white;
    const Color borderColor = Color(0xFFE5E7EB);
    const Color lightBlue = Color(0xFFEAF2FF);
    const Color textDark = Color(0xFF1F2937);
    const Color textMuted = Color(0xFF6B7280);

    InputDecoration inputDecoration(String hintText, {Widget? suffixIcon}) {
      return InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 1.2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: textDark),
          onPressed: () {},
        ),
        title: const Text(
          'Hasta Kaydı',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: textDark),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: primaryBlue,
              child: Text(
                'AK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryBlue,
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: const TextStyle(fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.app_registration),
            label: 'Register',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Evaluate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Reports',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: lightBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.badge_outlined,
                                color: primaryBlue,
                                size: 22,
                              ),
                            ),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Demografik Bilgiler',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '2. Adım',
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Kişisel Bilgiler',
                                    style: TextStyle(
                                      color: textDark,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: borderColor),
                        const SizedBox(height: 20),

                        const Text(
                          'AD',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          decoration: inputDecoration('Ad giriniz'),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'SOYAD',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: surnameController,
                          decoration: inputDecoration('Soyad giriniz'),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'CİNSİYET',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedGender,
                          decoration: inputDecoration('Cinsiyet seçiniz'),
                          items: const [
                            DropdownMenuItem(
                              value: 'Kadın',
                              child: Text('Kadın'),
                            ),
                            DropdownMenuItem(
                              value: 'Erkek',
                              child: Text('Erkek'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value;
                              widget.formData.genderId = mapGenderToId(value);
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'DOĞUM TARİHİ',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: birthDateController,
                          readOnly: true,
                          onTap: _selectDate,
                          decoration: inputDecoration(
                            'GG/AA/YYYY',
                            suffixIcon:
                            const Icon(Icons.calendar_today_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'TELEFON NUMARASI',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: inputDecoration(
                            'Telefon numarası giriniz',
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'YAŞADIĞI YER',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: cityController,
                          decoration: inputDecoration('Şehir / ilçe giriniz'),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'DOMİNANT TARAF',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedDominantSide,
                          decoration: inputDecoration(
                            'Dominant taraf seçiniz',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Sağ',
                              child: Text('Sağ'),
                            ),
                            DropdownMenuItem(
                              value: 'Sol',
                              child: Text('Sol'),
                            ),
                            DropdownMenuItem(
                              value: 'Her ikisi',
                              child: Text('Her ikisi'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedDominantSide = value;
                              widget.formData.dominantSideId =
                                  mapDominantSideToId(value);
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'EMPETICA ID',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: empeticaController,
                          decoration: inputDecoration('Empetica ID giriniz'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: borderColor),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Geri'),
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
                                SnackBar(content: Text(error)),
                              );
                              return;
                            }

                            widget.formData.name = nameController.text.trim();
                            widget.formData.surname =
                                surnameController.text.trim();
                            widget.formData.gender = selectedGender ?? '';
                            widget.formData.genderId =
                                mapGenderToId(selectedGender);

                            widget.formData.birthDate =
                                birthDateController.text.trim();
                            widget.formData.phone = phoneController.text.trim();
                            widget.formData.city = cityController.text.trim();

                            widget.formData.dominantSide =
                                selectedDominantSide ?? '';
                            widget.formData.dominantSideId =
                                mapDominantSideToId(selectedDominantSide);

                            widget.formData.empeticaId =
                                empeticaController.text.trim();
                            widget.formData.empaticaId =
                                int.tryParse(empeticaController.text.trim());

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PatientStep3Screen(formData: widget.formData),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Devam'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(8, (index) {
                      final bool isActive = index == 1;
                      final bool isDone = index == 0;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? primaryBlue
                              : isDone
                              ? const Color(0xFFDBEAFE)
                              : const Color(0xFFF3F4F6),
                          border: Border.all(
                            color: isActive || isDone
                                ? primaryBlue
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                            Icons.check,
                            size: 14,
                            color: primaryBlue,
                          )
                              : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      );
                    }),
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