import 'package:flutter/material.dart';
import '../models/patient_form_data.dart';
import 'patient_step_5_screen.dart';
import 'main_screen.dart';
import '../services/supabase_service.dart';

class PatientStep4Screen extends StatefulWidget {
  final PatientFormData formData;

  const PatientStep4Screen({
    super.key,
    required this.formData,
  });

  @override
  State<PatientStep4Screen> createState() => _PatientStep4ScreenState();
}

class _PatientStep4ScreenState extends State<PatientStep4Screen> {
  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kPrimary = Color(0xFF124153);
  static const Color kTextDark = Color(0xFF124153);
  static const Color kTextGrey = Color(0xFF64748B);
  static const Color kTextHint = Color(0xFF94A3B8);
  static const Color kInputFill = Color(0xFFF1F5F9);
  static const Color kBorderColor = Color(0xFFE2E8F0);

  List<Map<String, dynamic>> educationOptions = [];
  List<Map<String, dynamic>> maritalStatusOptions = [];
  List<Map<String, dynamic>> occupationOptions = [];

  String? selectedEducation;
  String? selectedMaritalStatus;
  String? selectedOccupation;

  int? selectedEducationId;
  int? selectedMaritalStatusId;
  int? selectedOccupationId;

  bool isLoadingOptions = true;

  @override
  void initState() {
    super.initState();

    selectedEducation =
    widget.formData.education.isEmpty ? null : widget.formData.education;
    selectedMaritalStatus = widget.formData.maritalStatus.isEmpty
        ? null
        : widget.formData.maritalStatus;
    selectedOccupation =
    widget.formData.occupation.isEmpty ? null : widget.formData.occupation;

    selectedEducationId = widget.formData.educationId;
    selectedMaritalStatusId = widget.formData.maritalStatusId;
    selectedOccupationId = widget.formData.occupationId;

    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final educationResponse = await SupabaseService.client
          .schema('neura')
          .from('egitimDurumlari')
          .select('egitimDurumId, egitimDurumAdi')
          .order('egitimDurumId', ascending: true);

      final maritalStatusResponse = await SupabaseService.client
          .schema('neura')
          .from('medeniDurumlar')
          .select('medeniDurumId, medeniDurumAdi')
          .order('medeniDurumId', ascending: true);

      final occupationResponse = await SupabaseService.client
          .schema('neura')
          .from('meslekler')
          .select('meslekId, meslekAdi')
          .order('meslekId', ascending: true);

      if (!mounted) return;

      final loadedEducationOptions =
      List<Map<String, dynamic>>.from(educationResponse);
      final loadedMaritalStatusOptions =
      List<Map<String, dynamic>>.from(maritalStatusResponse);
      final loadedOccupationOptions =
      List<Map<String, dynamic>>.from(occupationResponse);

      String? loadedSelectedEducation = selectedEducation;
      String? loadedSelectedMaritalStatus = selectedMaritalStatus;
      String? loadedSelectedOccupation = selectedOccupation;

      if (selectedEducationId != null && loadedSelectedEducation == null) {
        final match = loadedEducationOptions.where(
              (item) => item['egitimDurumId'] == selectedEducationId,
        );

        if (match.isNotEmpty) {
          loadedSelectedEducation =
              match.first['egitimDurumAdi']?.toString();
        }
      }

      if (selectedMaritalStatusId != null &&
          loadedSelectedMaritalStatus == null) {
        final match = loadedMaritalStatusOptions.where(
              (item) => item['medeniDurumId'] == selectedMaritalStatusId,
        );

        if (match.isNotEmpty) {
          loadedSelectedMaritalStatus =
              match.first['medeniDurumAdi']?.toString();
        }
      }

      if (selectedOccupationId != null && loadedSelectedOccupation == null) {
        final match = loadedOccupationOptions.where(
              (item) => item['meslekId'] == selectedOccupationId,
        );

        if (match.isNotEmpty) {
          loadedSelectedOccupation = match.first['meslekAdi']?.toString();
        }
      }

      setState(() {
        educationOptions = loadedEducationOptions;
        maritalStatusOptions = loadedMaritalStatusOptions;
        occupationOptions = loadedOccupationOptions;

        selectedEducation = loadedSelectedEducation;
        selectedMaritalStatus = loadedSelectedMaritalStatus;
        selectedOccupation = loadedSelectedOccupation;

        isLoadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingOptions = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seçenekler yüklenemedi: $e'),
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

  Widget selectionTile({
    required String title,
    required int value,
    required int? groupValue,
    required ValueChanged<int?> onChanged,
    bool fullWidth = false,
  }) {
    final bool isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: fullWidth ? double.infinity : null,
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
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
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
                                Icons.school_outlined,
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
                                    '4. Adım',
                                    style: TextStyle(
                                      color: kPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Sosyal ve Eğitim',
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
                          'EĞİTİM DURUMU',
                          style: labelStyle,
                        ),
                        const SizedBox(height: 12),
                        isLoadingOptions
                            ? _loadingBox()
                            : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: educationOptions.map((education) {
                            final int id =
                            education['egitimDurumId'] as int;
                            final String name =
                                education['egitimDurumAdi']
                                    ?.toString() ??
                                    '';

                            return selectionTile(
                              title: name,
                              value: id,
                              groupValue: selectedEducationId,
                              onChanged: (value) {
                                if (value == null) return;

                                setState(() {
                                  selectedEducationId = value;
                                  selectedEducation = name;
                                });

                                widget.formData.educationId = value;
                                widget.formData.education = name;
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        const Text(
                          'MEDENİ DURUM',
                          style: labelStyle,
                        ),
                        const SizedBox(height: 12),
                        isLoadingOptions
                            ? _loadingBox()
                            : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                          maritalStatusOptions.map((maritalStatus) {
                            final int id =
                            maritalStatus['medeniDurumId'] as int;
                            final String name =
                                maritalStatus['medeniDurumAdi']
                                    ?.toString() ??
                                    '';

                            return selectionTile(
                              title: name,
                              value: id,
                              groupValue: selectedMaritalStatusId,
                              onChanged: (value) {
                                if (value == null) return;

                                setState(() {
                                  selectedMaritalStatusId = value;
                                  selectedMaritalStatus = name;
                                });

                                widget.formData.maritalStatusId = value;
                                widget.formData.maritalStatus = name;
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        const Text(
                          'MESLEK',
                          style: labelStyle,
                        ),
                        const SizedBox(height: 12),
                        isLoadingOptions
                            ? _loadingBox()
                            : Column(
                          children: occupationOptions.map((occupation) {
                            final int id = occupation['meslekId'] as int;
                            final String name =
                                occupation['meslekAdi']?.toString() ?? '';

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 10,
                              ),
                              child: selectionTile(
                                title: name,
                                value: id,
                                groupValue: selectedOccupationId,
                                fullWidth: true,
                                onChanged: (value) {
                                  if (value == null) return;

                                  setState(() {
                                    selectedOccupationId = value;
                                    selectedOccupation = name;
                                  });

                                  widget.formData.occupationId = value;
                                  widget.formData.occupation = name;
                                },
                              ),
                            );
                          }).toList(),
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
                            widget.formData.education =
                                selectedEducation ?? '';
                            widget.formData.educationId =
                                selectedEducationId;

                            widget.formData.maritalStatus =
                                selectedMaritalStatus ?? '';
                            widget.formData.maritalStatusId =
                                selectedMaritalStatusId;

                            widget.formData.occupation =
                                selectedOccupation ?? '';
                            widget.formData.occupationId =
                                selectedOccupationId;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientStep5Screen(
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

  Widget _loadingBox() {
    return Container(
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
    );
  }
}