import 'package:flutter/material.dart';
import '../models/patient_form_data.dart';
import 'patient_step_7_screen.dart';

class PatientStep6Screen extends StatefulWidget {
  final PatientFormData formData;

  const PatientStep6Screen({
    super.key,
    required this.formData,
  });

  @override
  State<PatientStep6Screen> createState() => _PatientStep6ScreenState();
}

class _PatientStep6ScreenState extends State<PatientStep6Screen> {
  // NeuraApp Tasarım Sistemi Renkleri
  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kPrimary = Color(0xFF2563EB); // HASTA SAYFASI
  static const Color kTextDark = Color(0xFF1E293B);
  static const Color kTextGrey = Color(0xFF64748B);
  static const Color kTextHint = Color(0xFF94A3B8);
  static const Color kInputFill = Color(0xFFF1F5F9);
  static const Color kBorderColor = Color(0xFFE2E8F0);

  String? smokingStatus;
  String? exerciseStatus;

  @override
  void initState() {
    super.initState();

    smokingStatus = widget.formData.smokingStatus.isEmpty
        ? null
        : widget.formData.smokingStatus;

    exerciseStatus = widget.formData.exerciseStatus.isEmpty
        ? null
        : widget.formData.exerciseStatus;
  }

  int? mapSmokingToId(String? value) {
    if (value == 'Yok') return 1;
    if (value == 'Var') return 2;
    if (value == 'Bırakmış') return 3;
    return null;
  }

  // NeuraApp Seçim Kutucuğu (Chip/Radio Alternatifi)
  Widget selectionTile({
    required String title,
    required String value,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final bool isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPrimary : kBorderColor,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: kPrimary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : kTextDark,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: kTextGrey,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );

    return Scaffold(
      backgroundColor: kBackground,
      // AppBar ve BottomNavigationBar kurallar gereği silindi.
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
                                Icons.spa_outlined,
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
                                    'EK BİLGİLER',
                                    style: TextStyle(
                                      color: kTextGrey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '6. Adım',
                                    style: TextStyle(
                                      color: kPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Yaşam Tarzı',
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

                        const Text('SİGARA KULLANIMI', style: labelStyle),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            selectionTile(
                              title: 'Yok',
                              value: 'Yok',
                              groupValue: smokingStatus,
                              onChanged: (value) {
                                setState(() {
                                  smokingStatus = value;
                                  widget.formData.smokingStatusId =
                                      mapSmokingToId(value);
                                });
                              },
                            ),
                            selectionTile(
                              title: 'Var',
                              value: 'Var',
                              groupValue: smokingStatus,
                              onChanged: (value) {
                                setState(() {
                                  smokingStatus = value;
                                  widget.formData.smokingStatusId =
                                      mapSmokingToId(value);
                                });
                              },
                            ),
                            selectionTile(
                              title: 'Bırakmış',
                              value: 'Bırakmış',
                              groupValue: smokingStatus,
                              onChanged: (value) {
                                setState(() {
                                  smokingStatus = value;
                                  widget.formData.smokingStatusId =
                                      mapSmokingToId(value);
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        const Text('DÜZENLİ EGZERSİZ ALIŞKANLIĞI', style: labelStyle),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            selectionTile(
                              title: 'Var',
                              value: 'Var',
                              groupValue: exerciseStatus,
                              onChanged: (value) {
                                setState(() => exerciseStatus = value);
                              },
                            ),
                            selectionTile(
                              title: 'Yok',
                              value: 'Yok',
                              groupValue: exerciseStatus,
                              onChanged: (value) {
                                setState(() => exerciseStatus = value);
                              },
                            ),
                          ],
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
                            widget.formData.smokingStatus =
                                smokingStatus ?? '';
                            widget.formData.smokingStatusId =
                                mapSmokingToId(smokingStatus);

                            widget.formData.exerciseStatus =
                                exerciseStatus ?? '';

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientStep7Screen(
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
                        final bool isActive = index == 5;
                        final bool isDone = index < 5;

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