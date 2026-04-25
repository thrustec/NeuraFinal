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

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2563EB);
    const Color background = Color(0xFFF5F7FB);
    const Color cardColor = Colors.white;
    const Color borderColor = Color(0xFFE5E7EB);
    const Color lightBlue = Color(0xFFEAF2FF);
    const Color textDark = Color(0xFF1F2937);
    const Color textMuted = Color(0xFF6B7280);

    Widget radioTile({
      required String title,
      required String value,
      required String? groupValue,
      required ValueChanged<String?> onChanged,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: primaryBlue,
                visualDensity: VisualDensity.compact,
              ),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
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
                                Icons.spa_outlined,
                                color: primaryBlue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ek Bilgiler',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '6. Adım',
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Yaşam Tarzı ve Alışkanlıklar',
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
                          'SİGARA KULLANIMI',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            radioTile(
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
                            radioTile(
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
                            radioTile(
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

                        const SizedBox(height: 20),

                        const Text(
                          'DÜZENLİ EGZERSİZ ALIŞKANLIĞI',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            radioTile(
                              title: 'Var',
                              value: 'Var',
                              groupValue: exerciseStatus,
                              onChanged: (value) {
                                setState(() => exerciseStatus = value);
                              },
                            ),
                            radioTile(
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
                      final bool isActive = index == 5;
                      final bool isDone = index < 5;

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