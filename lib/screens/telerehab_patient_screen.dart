import 'package:flutter/material.dart';
import '../services/meeting_service.dart';

// NeuraApp Design System — Hasta Renk Paleti
const Color kBackground = Color(0xFFF8F9FC);
const Color kPrimary = Color(0xFF2563EB);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF64748B);
const Color kTextHint = Color(0xFF94A3B8);
const Color kInputFill = Color(0xFFF1F5F9);

class TelerehabPatientScreen extends StatefulWidget {
  const TelerehabPatientScreen({super.key});

  @override
  State<TelerehabPatientScreen> createState() =>
      _TelerehabPatientScreenState();
}

class _TelerehabPatientScreenState extends State<TelerehabPatientScreen> {
  final MeetingService meetingService = MeetingService();

  bool isLoading = true;
  bool isSendingRequest = false;

  final int currentPatientId = 1;
  int selectedClinicianId = 1;

  final TextEditingController requestController =
  TextEditingController(text: 'Yeni telerehabilitasyon talebi');

  List<Map<String, dynamic>> meetings = [];
  List<Map<String, dynamic>> clinicians = [];

  @override
  void initState() {
    super.initState();
    loadPageData();
  }

  Future<void> loadPageData() async {
    try {
      final fetchedMeetings =
      await meetingService.getMeetingsByPatient(currentPatientId);
      final fetchedClinicians = await meetingService.getClinicians();

      if (!mounted) return;

      setState(() {
        meetings = fetchedMeetings;
        clinicians = fetchedClinicians;

        if (clinicians.isNotEmpty) {
          selectedClinicianId = clinicians.first['kullaniciId'] as int;
        }

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler yüklenemedi: $e')),
      );
    }
  }

  Future<void> sendMeetingRequest() async {
    try {
      setState(() {
        isSendingRequest = true;
      });

      await meetingService.createMeetingRequest(
        toplantiId: null,
        hastaId: currentPatientId,
        klinisyenId: selectedClinicianId,
        durum: 'Beklemede',
        talep: requestController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toplantı talebi gönderildi.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSendingRequest = false;
        });
      }
    }
  }

  @override
  void dispose() {
    requestController.dispose();
    super.dispose();
  }

  // ── UI Yardımcıları ──────────────────────────────────────

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kTextHint, fontSize: 14),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: kInputFill,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _meetingItem(Map<String, dynamic> meeting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: kPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meeting['baslik'] ?? 'Başlıksız',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow(Icons.play_circle_outline,
              'Başlangıç: ${meeting['baslangicZamani']}'),
          _infoRow(Icons.stop_circle_outlined,
              'Bitiş: ${meeting['bitisZamani']}'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: kTextHint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: kTextGrey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: kPrimary, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Telerehabilitasyon',
          style: TextStyle(
            color: kTextDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
            child: CircularProgressIndicator(color: kPrimary))
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            children: [
              // ── Toplantılarım ──
              _sectionCard(
                title: 'Toplantılarım',
                icon: Icons.calendar_month_outlined,
                children: meetings.isEmpty
                    ? [
                  const Text(
                    'Henüz toplantınız yok.',
                    style: TextStyle(
                        color: kTextHint, fontSize: 14),
                  ),
                ]
                    : meetings.map(_meetingItem).toList(),
              ),

              // ── Yeni Talep Oluştur ──
              _sectionCard(
                title: 'Yeni Talep Oluştur',
                icon: Icons.send_outlined,
                children: [
                  const Text(
                    'KLİNİSYEN',
                    style: TextStyle(
                      color: kTextGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedClinicianId,
                    decoration: _inputDecoration('Klinisyen seçin'),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: kPrimary),
                    items: clinicians
                        .map((item) => DropdownMenuItem<int>(
                      value: item['kullaniciId'] as int,
                      child: Text(
                        '${item['ad']} ${item['soyad'] ?? ''}',
                        style: const TextStyle(
                            color: kTextDark, fontSize: 14),
                      ),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClinicianId = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TALEP MESAJI',
                    style: TextStyle(
                      color: kTextGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: requestController,
                    maxLines: 3,
                    style: const TextStyle(
                        color: kTextDark, fontSize: 14),
                    decoration:
                    _inputDecoration('Talep mesajınızı yazın'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isSendingRequest
                          ? null
                          : sendMeetingRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(14)),
                      ),
                      icon: isSendingRequest
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.send_outlined,
                          size: 18),
                      label: const Text(
                        'Toplantı Talebi Gönder',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}