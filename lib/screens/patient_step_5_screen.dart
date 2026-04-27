import 'package:flutter/material.dart';
import '../models/patient_form_data.dart';
import 'patient_step_6_screen.dart';

class PatientStep5Screen extends StatefulWidget {
  final PatientFormData formData;

  const PatientStep5Screen({
    super.key,
    required this.formData,
  });

  @override
  State<PatientStep5Screen> createState() => _PatientStep5ScreenState();
}

class _PatientStep5ScreenState extends State<PatientStep5Screen> {
  // NeuraApp Renk Paleti
  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kPrimary = Color(0xFF2563EB); // HASTA SAYFASI
  static const Color kTextDark = Color(0xFF1E293B);
  static const Color kTextGrey = Color(0xFF64748B);
  static const Color kTextHint = Color(0xFF94A3B8);
  static const Color kInputFill = Color(0xFFF1F5F9);
  static const Color kBorderColor = Color(0xFFE2E8F0);

  final TextEditingController complaintHistoryController =
  TextEditingController();
  final TextEditingController complaintDateController =
  TextEditingController();
  final TextEditingController medicationsController =
  TextEditingController();

  String? selectedDiagnosis;

  @override
  void initState() {
    super.initState();

    complaintHistoryController.text = widget.formData.complaintHistory;
    complaintDateController.text = widget.formData.complaintDate;
    medicationsController.text = widget.formData.medications;

    selectedDiagnosis =
    widget.formData.diagnosis.isEmpty ? null : widget.formData.diagnosis;
  }

  @override
  void dispose() {
    complaintHistoryController.dispose();
    complaintDateController.dispose();
    medicationsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime initialDate = DateTime.now();

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
        complaintDateController.text =
        "${picked.day.toString().padLeft(2, '0')}/"
            "${picked.month.toString().padLeft(2, '0')}/"
            "${picked.year}";
      });
    }
  }

  int? mapDiagnosisToId(String? value) {
    if (value == 'MS') return 1;
    if (value == 'Parkinson') return 2;
    if (value == 'Diabetes') return 3;
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

    const labelStyle = TextStyle(
      color: kTextGrey,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );

    return Scaffold(
      backgroundColor: kBackground,
      // AppBar ve BottomNavigationBar kurallar gereği (alt sayfa varsayımıyla) silindi.
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
                                Icons.medical_information_outlined,
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
                                    'KLİNİK BİLGİLER',
                                    style: TextStyle(
                                      color: kTextGrey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '5. Adım',
                                    style: TextStyle(
                                      color: kPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Tıbbi Bilgiler',
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

                        const Text('HASTALIK HİKAYESİ / İLK ŞİKAYETLER', style: labelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: complaintHistoryController,
                          maxLines: 4,
                          style: const TextStyle(color: kTextDark),
                          decoration: inputDecoration('Şikayet geçmişini giriniz'),
                        ),

                        const SizedBox(height: 20),

                        const Text('İLK ŞİKAYETLERİN BAŞLADIĞI TARİH', style: labelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: complaintDateController,
                          readOnly: true,
                          onTap: _selectDate,
                          style: const TextStyle(color: kTextDark),
                          decoration: inputDecoration(
                            'GG/AA/YYYY',
                            suffixIcon: const Icon(Icons.calendar_today_outlined, color: kPrimary, size: 20),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text('TANI', style: labelStyle),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedDiagnosis,
                          decoration: inputDecoration('Tanı seçiniz'),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kTextGrey),
                          borderRadius: BorderRadius.circular(14),
                          dropdownColor: Colors.white,
                          items: const [
                            DropdownMenuItem(value: 'MS', child: Text('MS')),
                            DropdownMenuItem(value: 'Parkinson', child: Text('Parkinson')),
                            DropdownMenuItem(value: 'Diabetes', child: Text('Diabetes')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedDiagnosis = value;
                              widget.formData.diagnosisId = mapDiagnosisToId(value);
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        const Text('KULLANILAN İLAÇLAR', style: labelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: medicationsController,
                          maxLines: 3,
                          style: const TextStyle(color: kTextDark),
                          decoration: inputDecoration('Kullanılan ilaçları giriniz'),
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
                            style: TextStyle(color: kTextGrey, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            widget.formData.complaintHistory =
                                complaintHistoryController.text.trim();
                            widget.formData.complaintDate =
                                complaintDateController.text.trim();
                            widget.formData.diagnosis =
                                selectedDiagnosis ?? '';
                            widget.formData.diagnosisId =
                                mapDiagnosisToId(selectedDiagnosis);
                            widget.formData.medications =
                                medicationsController.text.trim();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientStep6Screen(
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
                        final bool isActive = index == 4;
                        final bool isDone = index < 4;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? kPrimary
                                : (isDone ? kPrimary.withOpacity(0.1) : Colors.white),
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