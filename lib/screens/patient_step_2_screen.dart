import 'package:flutter/material.dart';
import '../models/patient_form_data.dart';
import '../utils/validators.dart';
import 'patient_step_3_screen.dart';
import 'package:flutter/services.dart';
import 'main_screen.dart';
import '../services/supabase_service.dart';

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
  static const Color kPrimary = Color(0xFF124153); // HASTA SAYFASI
  static const Color kTextDark = Color(0xFF124153);
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

  List<Map<String, dynamic>> genderOptions = [];
  List<Map<String, dynamic>> dominantSideOptions = [];

  int? selectedGenderId;
  int? selectedDominantSideId;

  String? selectedGender;
  String? selectedDominantSide;

  bool isLoadingOptions = true;

  @override
  void initState() {
    super.initState();

    nameController.text = widget.formData.name;
    surnameController.text = widget.formData.surname;
    birthDateController.text = widget.formData.birthDate;
    phoneController.text = widget.formData.phone;
    cityController.text = widget.formData.city;
    empeticaController.text = widget.formData.empeticaId;

    selectedGenderId = widget.formData.genderId;
    selectedDominantSideId = widget.formData.dominantSideId;

    selectedGender =
    widget.formData.gender.isEmpty ? null : widget.formData.gender;

    selectedDominantSide = widget.formData.dominantSide.isEmpty
        ? null
        : widget.formData.dominantSide;

    _loadDropdownOptions();
  }

  Future<void> _loadDropdownOptions() async {
    try {
      final gendersResponse = await SupabaseService.client
          .schema('neura')
          .from('cinsiyetler')
          .select('cinsiyetId, cinsiyetAdi')
          .order('cinsiyetId', ascending: true);

      final dominantSidesResponse = await SupabaseService.client
          .schema('neura')
          .from('baskin')
          .select('baskinId, elAdi')
          .order('baskinId', ascending: true);

      if (!mounted) return;

      final loadedGenders =
      List<Map<String, dynamic>>.from(gendersResponse);

      final loadedDominantSides =
      List<Map<String, dynamic>>.from(dominantSidesResponse);

      String? loadedSelectedGender = selectedGender;
      String? loadedSelectedDominantSide = selectedDominantSide;

      if (selectedGenderId != null && loadedSelectedGender == null) {
        final matchedGender = loadedGenders.where(
              (gender) => gender['cinsiyetId'] == selectedGenderId,
        );

        if (matchedGender.isNotEmpty) {
          loadedSelectedGender =
              matchedGender.first['cinsiyetAdi']?.toString();
        }
      }

      if (selectedDominantSideId != null &&
          loadedSelectedDominantSide == null) {
        final matchedDominantSide = loadedDominantSides.where(
              (side) => side['baskinId'] == selectedDominantSideId,
        );

        if (matchedDominantSide.isNotEmpty) {
          loadedSelectedDominantSide =
              matchedDominantSide.first['elAdi']?.toString();
        }
      }

      setState(() {
        genderOptions = loadedGenders;
        dominantSideOptions = loadedDominantSides;
        selectedGender = loadedSelectedGender;
        selectedDominantSide = loadedSelectedDominantSide;
        isLoadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingOptions = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cinsiyet ve dominant taraf seçenekleri yüklenemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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

  Future<void> _showExitFormDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Formdan çık'),
          content: const Text(
            'Formdan çıkmak istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Forma devam et'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Formdan çık'),
            ),
          ],
        );
      },
    );

    if (shouldExit == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(isClinician: true),
        ),
            (route) => false,
      );
    }
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: kTextDark,
          ),
          onPressed: _showExitFormDialog,
        ),
      ),
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
                        isLoadingOptions
                            ? Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: kInputFill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: kPrimary,
                            ),
                          ),
                        )
                            : DropdownButtonFormField<int>(
                          value: selectedGenderId,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: kTextGrey,
                          ),
                          decoration:
                          inputDecoration('Cinsiyet seçiniz'),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          items: genderOptions.map((gender) {
                            final int id =
                            gender['cinsiyetId'] as int;
                            final String name =
                                gender['cinsiyetAdi']?.toString() ?? '';

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: kTextDark,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            final selected = genderOptions.firstWhere(
                                  (gender) =>
                              gender['cinsiyetId'] == value,
                            );

                            setState(() {
                              selectedGenderId = value;
                              selectedGender =
                                  selected['cinsiyetAdi']?.toString() ??
                                      '';
                            });

                            widget.formData.genderId = value;
                            widget.formData.gender =
                                selectedGender ?? '';
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
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              color: kPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text('TELEFON NUMARASI', style: labelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: kTextDark),
                          maxLength: 11,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: inputDecoration(
                            'Telefon numarası giriniz',
                          ).copyWith(
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text('YAŞADIĞI YER', style: labelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: cityController,
                          style: const TextStyle(color: kTextDark),
                          decoration:
                          inputDecoration('Şehir / ilçe giriniz'),
                        ),
                        const SizedBox(height: 20),

                        const Text('DOMİNANT TARAF', style: labelStyle),
                        const SizedBox(height: 10),
                        isLoadingOptions
                            ? Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: kInputFill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: kPrimary,
                            ),
                          ),
                        )
                            : DropdownButtonFormField<int>(
                          value: selectedDominantSideId,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: kTextGrey,
                          ),
                          decoration:
                          inputDecoration('Dominant taraf seçiniz'),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          items: dominantSideOptions.map((side) {
                            final int id = side['baskinId'] as int;
                            final String name =
                                side['elAdi']?.toString() ?? '';

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: kTextDark,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            final selected =
                            dominantSideOptions.firstWhere(
                                  (side) => side['baskinId'] == value,
                            );

                            setState(() {
                              selectedDominantSideId = value;
                              selectedDominantSide =
                                  selected['elAdi']?.toString() ?? '';
                            });

                            widget.formData.dominantSideId = value;
                            widget.formData.dominantSide =
                                selectedDominantSide ?? '';
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
                          child: const Text(
                            'Geri',
                            style: TextStyle(
                              color: kTextGrey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                            widget.formData.surname =
                                surnameController.text.trim();
                            widget.formData.gender = selectedGender ?? '';
                            widget.formData.genderId = selectedGenderId;
                            widget.formData.birthDate =
                                birthDateController.text.trim();
                            widget.formData.phone =
                                phoneController.text.trim();
                            widget.formData.city = cityController.text.trim();
                            widget.formData.dominantSide =
                                selectedDominantSide ?? '';
                            widget.formData.dominantSideId =
                                selectedDominantSideId;
                            widget.formData.empeticaId =
                                empeticaController.text.trim();
                            widget.formData.empaticaId =
                                int.tryParse(empeticaController.text.trim());

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientStep3Screen(
                                  formData: widget.formData,
                                ),
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
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                            color: isActive
                                ? kPrimary
                                : (isDone
                                ? kPrimary.withOpacity(0.1)
                                : Colors.white),
                            border: Border.all(
                              color: (isActive || isDone)
                                  ? kPrimary
                                  : kBorderColor,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(
                              Icons.check,
                              size: 16,
                              color: kPrimary,
                            )
                                : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? Colors.white
                                    : kTextHint,
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