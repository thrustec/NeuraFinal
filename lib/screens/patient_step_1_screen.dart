import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/validators.dart';
import '../models/patient_form_data.dart';
import '../providers/auth_provider.dart';
import '../services/meeting_service.dart';
import 'patient_step_2_screen.dart';

class PatientStep1Screen extends StatefulWidget {
  const PatientStep1Screen({super.key});

  @override
  State<PatientStep1Screen> createState() => _PatientStep1ScreenState();
}

class _PatientStep1ScreenState extends State<PatientStep1Screen> {
  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kPrimary = Color(0xFF125F5F);
  static const Color kTextDark = Color(0xFF124153);
  static const Color kTextGrey = Color(0xFF64748B);
  static const Color kTextHint = Color(0xFF94A3B8);
  static const Color kInputFill = Color(0xFFF1F5F9);
  static const Color kBorderColor = Color(0xFFE2E8F0);

  final PatientFormData formData = PatientFormData();
  final MeetingService _meetingService = MeetingService();

  List<Map<String, dynamic>> _patients = [];
  Map<String, dynamic>? _selectedPatient;
  bool _isLoadingPatients = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final auth = context.read<AuthProvider>();
      final kullaniciId = int.tryParse(auth.user?.id ?? '');

      if (kullaniciId == null) {
        setState(() => _isLoadingPatients = false);
        return;
      }

      final clinician = await _meetingService.getClinicianByUserId(kullaniciId);

      if (clinician == null) {
        setState(() => _isLoadingPatients = false);
        return;
      }

      final klinisyenId = clinician['klinisyenId'] as int;

      final patients = await _meetingService.getPatientsByClinician(klinisyenId);

      if (!mounted) return;

      setState(() {
        _patients = patients;
        _isLoadingPatients = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPatients = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hasta listesi yüklenemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _selectPatient(Map<String, dynamic>? value) {
    if (value == null) return;

    final user = value['kullanicilar'];

    setState(() {
      _selectedPatient = value;

      formData.hastaId = value['hastaId'] as int?;
      formData.kullaniciId = value['kullaniciId'] as int?;

      formData.patientEmail = user?['eposta']?.toString() ?? '';
      formData.name = user?['ad']?.toString() ?? '';
      formData.surname = user?['soyad']?.toString() ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
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
                                Icons.groups_2_outlined,
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
                                    '1. Adım',
                                    style: TextStyle(
                                      color: kPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Hasta Kullanıcısı Seçimi',
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
                        const Text(
                          'KAYITLI HASTA KULLANICISI',
                          style: TextStyle(
                            color: kTextGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _isLoadingPatients
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
                            : DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedPatient,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: _patients.isEmpty
                                ? 'Kayıtlı hasta bulunamadı'
                                : 'Hasta e-postası seçiniz',
                            hintStyle:
                            const TextStyle(color: kTextHint),
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
                              borderSide: const BorderSide(
                                color: kPrimary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          items: _patients.map((patient) {
                            final user = patient['kullanicilar'];
                            final email =
                                user?['eposta']?.toString() ?? '-';
                            final ad = user?['ad']?.toString() ?? '';
                            final soyad =
                                user?['soyad']?.toString() ?? '';

                            return DropdownMenuItem(
                              value: patient,
                              child: Text(
                                '$email  ${ad.isNotEmpty || soyad.isNotEmpty ? "($ad $soyad)" : ""}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kTextDark,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: _selectPatient,
                        ),

                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kInputFill.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorderColor),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: kPrimary,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Klinisyene kayıtlı hasta seçildiğinde, sonraki adımda ad ve soyad otomatik dolar.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: kTextGrey,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                          onPressed: null,
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
                              color: kTextHint,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_selectedPatient == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Lütfen kayıtlı hasta kullanıcısı seçin.',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            final error =
                            PatientValidators.validateStep1(
                              patientEmail: formData.patientEmail,
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

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PatientStep2Screen(formData: formData),
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
                        final bool isActive = index == 0;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? kPrimary : Colors.white,
                            border: Border.all(
                              color: isActive ? kPrimary : kBorderColor,
                              width: 1.5,
                            ),
                            boxShadow: isActive
                                ? [
                              BoxShadow(
                                color: kPrimary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
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