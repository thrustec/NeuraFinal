import 'package:flutter/material.dart';
import '../models/patient_form_data.dart';
import '../utils/validators.dart';
import 'patient_step_4_screen.dart';

class PatientStep3Screen extends StatefulWidget {
  final PatientFormData formData;

  const PatientStep3Screen({
    super.key,
    required this.formData,
  });

  @override
  State<PatientStep3Screen> createState() => _PatientStep3ScreenState();
}

class _PatientStep3ScreenState extends State<PatientStep3Screen> {
  // NeuraApp Tasarım Sistemi Renkleri
  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kPrimary = Color(0xFF2563EB); // HASTA SAYFASI
  static const Color kTextDark = Color(0xFF1E293B);
  static const Color kTextGrey = Color(0xFF64748B);
  static const Color kTextHint = Color(0xFF94A3B8);
  static const Color kInputFill = Color(0xFFF1F5F9);
  static const Color kBorderColor = Color(0xFFE2E8F0);

  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    heightController.text = widget.formData.height;
    weightController.text = widget.formData.weight;
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  double? parseNumber(String value) {
    final cleaned = value.replaceAll(',', '.').trim();
    return double.tryParse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    // NeuraApp Input Dekorasyonu
    InputDecoration inputDecoration(String hintText, {Widget? suffix}) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: kTextHint, fontSize: 14),
        suffixIcon: suffix,
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

    // Etiket Stili
    const labelStyle = TextStyle(
      color: kTextGrey,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );

    return Scaffold(
      backgroundColor: kBackground,
      // AppBar ve BottomNavigationBar kurallar gereği (alt sayfa varsayımıyla) kaldırıldı.
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
                                Icons.straighten_outlined,
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
                                  const SizedBox(height: 4),
                                  const Text(
                                    '3. Adım',
                                    style: TextStyle(
                                      color: kPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Fiziksel Özellikler',
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

                        const Text('BOY (CM)', style: labelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: heightController,
                          style: const TextStyle(color: kTextDark, fontWeight: FontWeight.w500),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: inputDecoration(
                            'Örn: 170',
                            suffix: const Padding(
                              padding: EdgeInsets.only(right: 12, top: 14),
                              child: Text('cm', style: TextStyle(color: kTextHint, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text('KİLO (KG)', style: labelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: weightController,
                          style: const TextStyle(color: kTextDark, fontWeight: FontWeight.w500),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: inputDecoration(
                            'Örn: 70',
                            suffix: const Padding(
                              padding: EdgeInsets.only(right: 12, top: 14),
                              child: Text('kg', style: TextStyle(color: kTextHint, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                            final error = PatientValidators.validateStep3(
                              height: heightController.text,
                              weight: weightController.text,
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

                            widget.formData.height =
                                heightController.text.trim();
                            widget.formData.weight =
                                weightController.text.trim();

                            widget.formData.heightValue =
                                parseNumber(heightController.text);
                            widget.formData.weightValue =
                                parseNumber(weightController.text);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientStep4Screen(
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
                        final bool isActive = index == 2;
                        final bool isDone = index < 2;

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