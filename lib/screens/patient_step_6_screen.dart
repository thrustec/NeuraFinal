import 'package:flutter/material.dart';
import '../models/patient_form_data.dart';
import 'patient_step_7_screen.dart';
import 'main_screen.dart';
import '../services/supabase_service.dart';

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
  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kPrimary = Color(0xFF124153);
  static const Color kTextDark = Color(0xFF124153);
  static const Color kTextGrey = Color(0xFF64748B);
  static const Color kTextHint = Color(0xFF94A3B8);
  static const Color kInputFill = Color(0xFFF1F5F9);
  static const Color kBorderColor = Color(0xFFE2E8F0);

  List<Map<String, dynamic>> smokingOptions = [];

  int? selectedSmokingStatusId;
  String? smokingStatus;
  String? exerciseStatus;

  bool isLoadingSmokingOptions = true;

  @override
  void initState() {
    super.initState();

    selectedSmokingStatusId = widget.formData.smokingStatusId;

    smokingStatus = widget.formData.smokingStatus.isEmpty
        ? null
        : widget.formData.smokingStatus;

    exerciseStatus = widget.formData.exerciseStatus.isEmpty
        ? null
        : widget.formData.exerciseStatus;

    _loadSmokingOptions();
  }

  Future<void> _loadSmokingOptions() async {
    try {
      final response = await SupabaseService.client
          .schema('neura')
          .from('sigaraDurumu')
          .select('sigaraDurumId, sigaraDurumAdi')
          .order('sigaraDurumId', ascending: true);

      if (!mounted) return;

      final loadedSmokingOptions =
      List<Map<String, dynamic>>.from(response);

      String? loadedSmokingStatus = smokingStatus;

      if (selectedSmokingStatusId != null && loadedSmokingStatus == null) {
        final matchedStatus = loadedSmokingOptions.where(
              (item) => item['sigaraDurumId'] == selectedSmokingStatusId,
        );

        if (matchedStatus.isNotEmpty) {
          loadedSmokingStatus =
              matchedStatus.first['sigaraDurumAdi']?.toString();
        }
      }

      setState(() {
        smokingOptions = loadedSmokingOptions;
        smokingStatus = loadedSmokingStatus;
        isLoadingSmokingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingSmokingOptions = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sigara kullanım seçenekleri yüklenemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showExitDialog() async {
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

  Widget smokingSelectionTile({
    required String title,
    required int value,
  }) {
    final bool isSelected = value == selectedSmokingStatusId;

    return InkWell(
      onTap: () {
        setState(() {
          selectedSmokingStatusId = value;
          smokingStatus = title;
        });

        widget.formData.smokingStatusId = value;
        widget.formData.smokingStatus = title;
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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
            fontWeight:
            isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget exerciseSelectionTile({
    required String title,
    required String value,
  }) {
    final bool isSelected = value == exerciseStatus;

    return InkWell(
      onTap: () {
        setState(() {
          exerciseStatus = value;
        });

        widget.formData.exerciseStatus = value;
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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
            fontWeight:
            isSelected ? FontWeight.bold : FontWeight.w500,
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: kTextDark,
          ),
          onPressed: _showExitDialog,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  20,
                ),
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
                        const Divider(
                          color: kBorderColor,
                          height: 1,
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'SİGARA KULLANIMI',
                          style: labelStyle,
                        ),
                        const SizedBox(height: 12),
                        isLoadingSmokingOptions
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
                            : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: smokingOptions.map((item) {
                            final int id =
                            item['sigaraDurumId'] as int;
                            final String name =
                                item['sigaraDurumAdi']?.toString() ?? '';

                            return smokingSelectionTile(
                              title: name,
                              value: id,
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        const Text(
                          'DÜZENLİ EGZERSİZ ALIŞKANLIĞI',
                          style: labelStyle,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            exerciseSelectionTile(
                              title: 'Var',
                              value: 'Var',
                            ),
                            exerciseSelectionTile(
                              title: 'Yok',
                              value: 'Yok',
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
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24,
              ),
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
                            side: const BorderSide(
                              color: kBorderColor,
                            ),
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
                                selectedSmokingStatusId;
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}