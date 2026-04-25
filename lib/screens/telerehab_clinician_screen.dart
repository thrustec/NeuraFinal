import 'package:flutter/material.dart';
import '../services/meeting_service.dart';

class TelerehabClinicianScreen extends StatefulWidget {
  const TelerehabClinicianScreen({super.key});

  @override
  State<TelerehabClinicianScreen> createState() =>
      _TelerehabClinicianScreenState();
}

class _TelerehabClinicianScreenState extends State<TelerehabClinicianScreen> {
  final MeetingService meetingService = MeetingService();

  bool isCreatingMeeting = false;
  bool isLoadingDropdownData = true;
  int? processingRequestId;

  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> clinicians = [];
  List<Map<String, dynamic>> meetings = [];
  List<Map<String, dynamic>> meetingRequests = [];

  final TextEditingController titleController =
  TextEditingController(text: 'Haftalık Telerehabilitasyon Seansı');
  final TextEditingController noteController = TextEditingController();
  final TextEditingController requestController = TextEditingController(
    text: 'Hasta için denge ve mobilite odaklı takip görüşmesi talep edildi.',
  );

  int? selectedPatientId;
  int? selectedClinicianId;
  String selectedStatus = 'Beklemede';

  DateTime selectedStartDateTime = DateTime.now().add(const Duration(days: 1));
  DateTime selectedEndDateTime =
  DateTime.now().add(const Duration(days: 1, hours: 1));

  final List<Map<String, dynamic>> sampleEmailLogs = [
    {
      'epostaKayitId': 1,
      'toplantiId': 101,
      'aliciEposta': 'ayse@example.com',
      'gonderildiMi': true,
      'gonderimTarihi': '17.04.2026 10:15',
      'hataMetni': null,
    },
    {
      'epostaKayitId': 2,
      'toplantiId': 102,
      'aliciEposta': 'mehmet@example.com',
      'gonderildiMi': false,
      'gonderimTarihi': null,
      'hataMetni': 'SMTP zaman aşımı',
    },
  ];

  @override
  void initState() {
    super.initState();
    loadDropdownData();
  }

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    requestController.dispose();
    super.dispose();
  }

  Future<void> loadDropdownData() async {
    try {
      final fetchedPatients = await meetingService.getPatients();
      final fetchedClinicians = await meetingService.getClinicians();
      final fetchedMeetings = await meetingService.getMeetings();
      final fetchedRequests = await meetingService.getMeetingRequests();

      if (!mounted) return;

      setState(() {
        patients = fetchedPatients;
        clinicians = fetchedClinicians;
        meetings = fetchedMeetings;
        meetingRequests = fetchedRequests;

        if (patients.isNotEmpty) {
          selectedPatientId = patients.first['hastaId'] as int;
        }

        if (clinicians.isNotEmpty) {
          selectedClinicianId = clinicians.first['kullaniciId'] as int;
        }

        isLoadingDropdownData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingDropdownData = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler yüklenemedi: $e')),
      );
    }
  }

  Future<void> createMeeting() async {
    if (selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hasta seçin.')),
      );
      return;
    }

    if (selectedClinicianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen klinisyen seçin.')),
      );
      return;
    }

    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen toplantı başlığı girin.')),
      );
      return;
    }

    if (selectedEndDateTime.isBefore(selectedStartDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitiş zamanı başlangıç zamanından önce olamaz.'),
        ),
      );
      return;
    }

    try {
      setState(() {
        isCreatingMeeting = true;
      });

      final createdMeeting = await meetingService.createMeeting(
        hastaId: selectedPatientId!,
        klinisyenId: selectedClinicianId!,
        baslik: titleController.text.trim(),
        baslangicZamani: selectedStartDateTime,
        bitisZamani: selectedEndDateTime,
        notlar: noteController.text.trim(),
      );

      await meetingService.createMeetingRequest(
        toplantiId: createdMeeting['toplantiId'] as int,
        hastaId: selectedPatientId!,
        klinisyenId: selectedClinicianId!,
        durum: selectedStatus,
        talep: requestController.text.trim().isEmpty
            ? 'Toplantı talebi oluşturuldu.'
            : requestController.text.trim(),
      );

      await loadDropdownData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Toplantı ve talep başarıyla oluşturuldu. ID: ${createdMeeting['toplantiId']}',
          ),
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
          isCreatingMeeting = false;
        });
      }
    }
  }

  Future<void> updateRequestStatus({
    required int toplantiIstegiId,
    required String durum,
  }) async {
    try {
      setState(() {
        processingRequestId = toplantiIstegiId;
      });

      await meetingService.updateMeetingRequestStatus(
        toplantiIstegiId: toplantiIstegiId,
        durum: durum,
      );

      await loadDropdownData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Talep durumu güncellendi: $durum'),
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
          processingRequestId = null;
        });
      }
    }
  }

  Future<void> _pickStartDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedStartDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedStartDateTime),
    );

    if (pickedTime == null) return;

    setState(() {
      selectedStartDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (selectedEndDateTime.isBefore(selectedStartDateTime)) {
        selectedEndDateTime = selectedStartDateTime.add(
          const Duration(minutes: 45),
        );
      }
    });
  }

  Future<void> _pickEndDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedEndDateTime,
      firstDate: selectedStartDateTime,
      lastDate: DateTime(2030),
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedEndDateTime),
    );

    if (pickedTime == null) return;

    setState(() {
      selectedEndDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  String formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
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
    const Color successGreen = Color(0xFF16A34A);
    const Color dangerRed = Color(0xFFDC2626);
    const Color warningOrange = Color(0xFFF59E0B);

    InputDecoration inputDecoration(String hintText, {Widget? suffixIcon}) {
      return InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 1.2),
        ),
      );
    }

    Widget sectionCard({
      required String sectionLabel,
      required String title,
      required IconData icon,
      required List<Widget> children,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
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
                    child: Icon(icon, color: primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sectionLabel,
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(
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
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );
    }

    Widget fieldLabel(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
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
          icon: const Icon(Icons.arrow_back_ios_new, color: textDark),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Telerehabilitasyon',
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
      body: SafeArea(
        child: isLoadingDropdownData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              sectionCard(
                sectionLabel: 'Ajanda / neura.toplantilar',
                title: 'Yaklaşan Toplantılar',
                icon: Icons.calendar_month_outlined,
                children: meetings.isEmpty
                    ? const [
                  Text(
                    'Henüz oluşturulmuş toplantı yok.',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 14,
                    ),
                  ),
                ]
                    : meetings
                    .map(
                      (meeting) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          meeting['baslik'] ?? '',
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toplantı ID: ${meeting['toplantiId']}',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Başlangıç: ${meeting['baslangicZamani']}',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bitiş: ${meeting['bitisZamani']}',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Not: ${meeting['notlar'] ?? '-'}',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.video_call_outlined,
                            ),
                            label: const Text('Seansı Başlat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .toList(),
              ),
              sectionCard(
                sectionLabel: 'Gelen Talepler / neura.toplantiIstekleri',
                title: 'Hasta Talepleri',
                icon: Icons.inbox_outlined,
                children: meetingRequests.isEmpty
                    ? const [
                  Text(
                    'Henüz gelen talep yok.',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 14,
                    ),
                  ),
                ]
                    : meetingRequests
                    .map(
                      (request) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Talep ID: ${request['toplantiIstegiId']}',
                          style: const TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hasta ID: ${request['hastaId']}',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Klinisyen ID: ${request['klinisyenId']}',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Durum: ${request['durum'] ?? '-'}',
                          style: const TextStyle(
                            color: warningOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Talep: ${request['talep'] ?? '-'}',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Oluşturma: ${request['olusturmaTarihi'] ?? '-'}',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if ((request['durum'] ?? '') ==
                            'Beklemede') ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: processingRequestId ==
                                      request[
                                      'toplantiIstegiId']
                                      ? null
                                      : () {
                                    updateRequestStatus(
                                      toplantiIstegiId:
                                      request[
                                      'toplantiIstegiId']
                                      as int,
                                      durum: 'Reddedildi',
                                    );
                                  },
                                  child: const Text('Reddet'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: processingRequestId ==
                                      request[
                                      'toplantiIstegiId']
                                      ? null
                                      : () {
                                    updateRequestStatus(
                                      toplantiIstegiId:
                                      request[
                                      'toplantiIstegiId']
                                      as int,
                                      durum: 'Onaylandı',
                                    );
                                  },
                                  child: processingRequestId ==
                                      request[
                                      'toplantiIstegiId']
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Text('Onayla'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                    .toList(),
              ),
              sectionCard(
                sectionLabel: 'Talep / neura.toplantiIstekleri',
                title: 'Yeni Toplantı Talebi Oluştur',
                icon: Icons.add_box_outlined,
                children: [
                  fieldLabel('HASTA ID (hastaId)'),
                  DropdownButtonFormField<int>(
                    initialValue: selectedPatientId,
                    decoration: inputDecoration('Hasta seçin'),
                    items: patients
                        .map(
                          (patient) => DropdownMenuItem<int>(
                        value: patient['hastaId'] as int,
                        child: Text('Hasta ID: ${patient['hastaId']}'),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPatientId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  fieldLabel('KLİNİSYEN ID (klinisyenId)'),
                  DropdownButtonFormField<int>(
                    initialValue: selectedClinicianId,
                    decoration: inputDecoration('Klinisyen seçin'),
                    items: clinicians
                        .map(
                          (clinician) => DropdownMenuItem<int>(
                        value: clinician['kullaniciId'] as int,
                        child: Text(
                          '${clinician['ad']} ${clinician['soyad'] ?? ''}',
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClinicianId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  fieldLabel('BAŞLIK (baslik)'),
                  TextField(
                    controller: titleController,
                    decoration: inputDecoration('Toplantı başlığı'),
                  ),
                  const SizedBox(height: 16),
                  fieldLabel('TALEP METNİ (talep)'),
                  TextField(
                    controller: requestController,
                    maxLines: 3,
                    decoration: inputDecoration('Toplantı talebini girin'),
                  ),
                  const SizedBox(height: 16),
                  fieldLabel('BAŞLANGIÇ ZAMANI (baslangicZamani)'),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: formatDateTime(selectedStartDateTime),
                    ),
                    onTap: _pickStartDateTime,
                    decoration: inputDecoration(
                      'Başlangıç zamanı seçin',
                      suffixIcon: const Icon(Icons.schedule_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  fieldLabel('BİTİŞ ZAMANI (bitisZamani)'),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: formatDateTime(selectedEndDateTime),
                    ),
                    onTap: _pickEndDateTime,
                    decoration: inputDecoration(
                      'Bitiş zamanı seçin',
                      suffixIcon: const Icon(Icons.schedule_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  fieldLabel('DURUM (durum)'),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: inputDecoration('Durum seçin'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Beklemede',
                        child: Text('Beklemede'),
                      ),
                      DropdownMenuItem(
                        value: 'Onaylandı',
                        child: Text('Onaylandı'),
                      ),
                      DropdownMenuItem(
                        value: 'İptal Edildi',
                        child: Text('İptal Edildi'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value ?? 'Beklemede';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  fieldLabel('NOTLAR (notlar)'),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration:
                    inputDecoration('Klinisyen notlarını girin'),
                  ),
                ],
              ),
              sectionCard(
                sectionLabel: 'E-posta Kaydı / neura.toplantiEpostaKayitlari',
                title: 'Davet Gönderim Durumu',
                icon: Icons.mail_outline,
                children: sampleEmailLogs
                    .map(
                      (log) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          (log['gonderildiMi'] as bool)
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: (log['gonderildiMi'] as bool)
                              ? successGreen
                              : dangerRed,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                log['aliciEposta'] ?? '',
                                style: const TextStyle(
                                  color: textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Toplantı ID: ${log['toplantiId']}',
                                style: const TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (log['gonderildiMi'] as bool)
                                    ? 'E-posta başarıyla gönderildi'
                                    : 'E-posta gönderilemedi: ${log['hataMetni'] ?? 'Bilinmeyen hata'}',
                                style: const TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              if (log['gonderimTarihi'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Gönderim zamanı: ${log['gonderimTarihi']}',
                                  style: const TextStyle(
                                    color: textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('E-posta Gönder'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isCreatingMeeting ? null : createMeeting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isCreatingMeeting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Toplantı Oluştur'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}