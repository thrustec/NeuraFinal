import 'package:flutter/material.dart';
import '../services/meeting_service.dart';

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
          selectedClinicianId =
          clinicians.first['kullaniciId'] as int;
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
        const SnackBar(
          content: Text('Toplantı talebi gönderildi.'),
        ),
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

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2563EB);
    const Color background = Color(0xFFF5F7FB);
    const Color cardColor = Colors.white;
    const Color borderColor = Color(0xFFE5E7EB);
    const Color lightBlue = Color(0xFFEAF2FF);
    const Color textDark = Color(0xFF1F2937);
    const Color textMuted = Color(0xFF6B7280);

    Widget card({
      required String title,
      required IconData icon,
      required List<Widget> children,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryBlue),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Hasta Telerehabilitasyon'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              card(
                title: 'Toplantılarım',
                icon: Icons.calendar_month,
                children: meetings.isEmpty
                    ? const [
                  Text(
                    'Henüz toplantınız yok.',
                    style: TextStyle(color: textMuted),
                  ),
                ]
                    : meetings
                    .map(
                      (meeting) => Container(
                    margin:
                    const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          meeting['baslik'] ??
                              'Başlıksız',
                          style: const TextStyle(
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                            'Başlangıç: ${meeting['baslangicZamani']}'),
                        Text(
                            'Bitiş: ${meeting['bitisZamani']}'),
                      ],
                    ),
                  ),
                )
                    .toList(),
              ),
              card(
                title: 'Yeni Talep Oluştur',
                icon: Icons.send,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedClinicianId,
                    decoration: const InputDecoration(
                      labelText: 'Klinisyen Seç',
                      border: OutlineInputBorder(),
                    ),
                    items: clinicians
                        .map(
                          (item) => DropdownMenuItem<int>(
                        value:
                        item['kullaniciId'] as int,
                        child: Text(
                          '${item['ad']} ${item['soyad'] ?? ''}',
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClinicianId = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: requestController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Talep Mesajı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSendingRequest
                          ? null
                          : sendMeetingRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize:
                        const Size.fromHeight(50),
                      ),
                      child: isSendingRequest
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
                        'Toplantı Talebi Gönder',
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