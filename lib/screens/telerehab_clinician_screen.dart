import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/meeting_service.dart';

// NeuraApp Design System — Klinisyen Renk Paleti
const Color kBackground = Color(0xFFF8F9FC);
const Color kPrimary = Color(0xFF0F766E);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF64748B);
const Color kTextHint = Color(0xFF94A3B8);
const Color kInputFill = Color(0xFFF1F5F9);
const Color kSuccess = Color(0xFF16A34A);
const Color kDanger = Color(0xFFDC2626);
const Color kWarning = Color(0xFFF59E0B);

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

      // Oturum açmış klinisyenin id'si — varsayılan seçim için
      final auth = context.read<AuthProvider>();
      final loggedClinicianId = int.tryParse(auth.user?.id ?? '');

      setState(() {
        patients = fetchedPatients;
        clinicians = fetchedClinicians;
        meetings = fetchedMeetings;
        meetingRequests = fetchedRequests;

        if (patients.isNotEmpty) {
          selectedPatientId = patients.first['hastaId'] as int;
        }

        if (loggedClinicianId != null &&
            clinicians.any((c) => c['kullaniciId'] == loggedClinicianId)) {
          selectedClinicianId = loggedClinicianId;
        } else if (clinicians.isNotEmpty) {
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

  /// Klinisyen Map'i için "Dr. Ayşe Yılmaz" gibi gösterim üretir.
  String _formatClinician(Map<String, dynamic> c) {
    final unvan = (c['unvan'] ?? '').toString().trim();
    final ad = (c['ad'] ?? '').toString().trim();
    final soyad = (c['soyad'] ?? '').toString().trim();

    return [unvan, ad, soyad].where((e) => e.isNotEmpty).join(' ').trim();
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
        SnackBar(content: Text('Talep durumu güncellendi: $durum')),
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
        selectedEndDateTime =
            selectedStartDateTime.add(const Duration(minutes: 45));
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

  // ── UI Yardımcıları ──────────────────────────────────────

  InputDecoration _inputDecoration(String hintText, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
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
    required String sectionLabel,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: kPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sectionLabel,
                        style: const TextStyle(
                          color: kTextGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          color: kTextDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: kTextGrey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _meetingItem(Map<String, dynamic> meeting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meeting['baslik'] ?? '',
            style: const TextStyle(
              color: kTextDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _infoRow(Icons.tag, 'Toplantı ID: ${meeting['toplantiId']}'),
          _infoRow(Icons.play_circle_outline,
              'Başlangıç: ${meeting['baslangicZamani']}'),
          _infoRow(
              Icons.stop_circle_outlined, 'Bitiş: ${meeting['bitisZamani']}'),
          _infoRow(Icons.notes_outlined, 'Not: ${meeting['notlar'] ?? '-'}'),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.video_call_outlined, size: 18),
              label: const Text(
                'Seansı Başlat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestItem(Map<String, dynamic> request) {
    final bool isPending = (request['durum'] ?? '') == 'Beklemede';
    final bool isProcessing =
        processingRequestId == request['toplantiIstegiId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  'Talep ID: ${request['toplantiIstegiId']}',
                  style: const TextStyle(
                    color: kTextDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kWarning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request['durum'] ?? '-',
                  style: const TextStyle(
                    color: kWarning,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow(Icons.person_outline, 'Hasta ID: ${request['hastaId']}'),
          _infoRow(Icons.medical_services_outlined,
              'Klinisyen ID: ${request['klinisyenId']}'),
          _infoRow(
              Icons.chat_bubble_outline, 'Talep: ${request['talep'] ?? '-'}'),
          _infoRow(Icons.calendar_today_outlined,
              'Oluşturma: ${request['olusturmaTarihi'] ?? '-'}'),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isProcessing
                        ? null
                        : () => updateRequestStatus(
                      toplantiIstegiId:
                      request['toplantiIstegiId'] as int,
                      durum: 'Reddedildi',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kDanger,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Reddet',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () => updateRequestStatus(
                      toplantiIstegiId:
                      request['toplantiIstegiId'] as int,
                      durum: 'Onaylandı',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Onayla',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
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

  Widget _emptyState(String message) {
    return Text(
      message,
      style: const TextStyle(color: kTextHint, fontSize: 14),
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
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: kTextGrey),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'AK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoadingDropdownData
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            children: [
              _sectionCard(
                sectionLabel: 'Ajanda / neura.toplantilar',
                title: 'Yaklaşan Toplantılar',
                icon: Icons.calendar_month_outlined,
                children: meetings.isEmpty
                    ? [_emptyState('Henüz oluşturulmuş toplantı yok.')]
                    : meetings.map(_meetingItem).toList(),
              ),
              _sectionCard(
                sectionLabel:
                'Gelen Talepler / neura.toplantiIstekleri',
                title: 'Hasta Talepleri',
                icon: Icons.inbox_outlined,
                children: meetingRequests.isEmpty
                    ? [_emptyState('Henüz gelen talep yok.')]
                    : meetingRequests.map(_requestItem).toList(),
              ),
              _sectionCard(
                sectionLabel: 'Talep / neura.toplantiIstekleri',
                title: 'Yeni Toplantı Talebi Oluştur',
                icon: Icons.add_box_outlined,
                children: [
                  _fieldLabel('HASTA ID (hastaId)'),
                  DropdownButtonFormField<int>(
                    value: selectedPatientId,
                    decoration: _inputDecoration('Hasta seçin'),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: kPrimary),
                    items: patients
                        .map((patient) => DropdownMenuItem<int>(
                      value: patient['hastaId'] as int,
                      child:
                      Text('Hasta ID: ${patient['hastaId']}'),
                    ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedPatientId = value),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('KLİNİSYEN'),
                  DropdownButtonFormField<int>(
                    value: selectedClinicianId,
                    decoration: _inputDecoration('Klinisyen seçin'),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: kPrimary),
                    isExpanded: true,
                    items: clinicians
                        .map((clinician) => DropdownMenuItem<int>(
                      value: clinician['kullaniciId'] as int,
                      child: Text(
                        _formatClinician(clinician),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedClinicianId = value),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('BAŞLIK (baslik)'),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(
                        color: kTextDark, fontSize: 14),
                    decoration: _inputDecoration('Toplantı başlığı'),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('TALEP METNİ (talep)'),
                  TextField(
                    controller: requestController,
                    maxLines: 3,
                    style: const TextStyle(
                        color: kTextDark, fontSize: 14),
                    decoration:
                    _inputDecoration('Toplantı talebini girin'),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('BAŞLANGIÇ ZAMANI (baslangicZamani)'),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(
                        text: formatDateTime(selectedStartDateTime)),
                    onTap: _pickStartDateTime,
                    style: const TextStyle(
                        color: kTextDark, fontSize: 14),
                    decoration: _inputDecoration(
                      'Başlangıç zamanı seçin',
                      suffixIcon: const Icon(Icons.schedule_outlined,
                          color: kPrimary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('BİTİŞ ZAMANI (bitisZamani)'),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(
                        text: formatDateTime(selectedEndDateTime)),
                    onTap: _pickEndDateTime,
                    style: const TextStyle(
                        color: kTextDark, fontSize: 14),
                    decoration: _inputDecoration(
                      'Bitiş zamanı seçin',
                      suffixIcon: const Icon(Icons.schedule_outlined,
                          color: kPrimary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('DURUM (durum)'),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: _inputDecoration('Durum seçin'),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: kPrimary),
                    items: const [
                      DropdownMenuItem(
                          value: 'Beklemede', child: Text('Beklemede')),
                      DropdownMenuItem(
                          value: 'Onaylandı', child: Text('Onaylandı')),
                      DropdownMenuItem(
                          value: 'İptal Edildi',
                          child: Text('İptal Edildi')),
                    ],
                    onChanged: (value) => setState(
                            () => selectedStatus = value ?? 'Beklemede'),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('NOTLAR (notlar)'),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    style: const TextStyle(
                        color: kTextDark, fontSize: 14),
                    decoration:
                    _inputDecoration('Klinisyen notlarını girin'),
                  ),
                ],
              ),
              _sectionCard(
                sectionLabel:
                'E-posta Kaydı / neura.toplantiEpostaKayitlari',
                title: 'Davet Gönderim Durumu',
                icon: Icons.mail_outline,
                children: sampleEmailLogs.map((log) {
                  final bool sent = log['gonderildiMi'] as bool;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kBackground,
                      borderRadius: BorderRadius.circular(14),
                      border:
                      Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: sent
                                ? kSuccess.withOpacity(0.1)
                                : kDanger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            sent
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: sent ? kSuccess : kDanger,
                            size: 20,
                          ),
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
                                  color: kTextDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Toplantı ID: ${log['toplantiId']}',
                                style: const TextStyle(
                                    color: kTextGrey, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sent
                                    ? 'E-posta başarıyla gönderildi'
                                    : 'Gönderilemedi: ${log['hataMetni'] ?? 'Bilinmeyen hata'}',
                                style: TextStyle(
                                  color: sent ? kSuccess : kDanger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (log['gonderimTarihi'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Gönderim zamanı: ${log['gonderimTarihi']}',
                                  style: const TextStyle(
                                      color: kTextGrey, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTextGrey,
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'E-posta Gönder',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isCreatingMeeting ? null : createMeeting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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
                    : const Text(
                  'Toplantı Oluştur',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
