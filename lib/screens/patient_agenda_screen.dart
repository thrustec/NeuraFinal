import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/patient.dart';
import '../services/meeting_service.dart';
import '../services/supabase_service.dart';

class PatientAgendaScreen extends StatefulWidget {
  final Patient patient;

  const PatientAgendaScreen({
    super.key,
    required this.patient,
  });

  @override
  State<PatientAgendaScreen> createState() => _PatientAgendaScreenState();
}

class _PatientAgendaScreenState extends State<PatientAgendaScreen> {
  final MeetingService _meetingService = MeetingService();
  final TextEditingController _requestController = TextEditingController();

  bool _isLoading = true;
  bool _isSending = false;

  int? _realHastaId;
  int? _assignedClinicianId;
  String _assignedClinicianName = 'Klinisyen bilgisi yükleniyor...';

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _approvedMeetings = [];

  static const Color kPrimary = Color(0xFF2563EB);
  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kSurface = Colors.white;
  static const Color kTextDark = Color(0xFF1E293B);
  static const Color kTextGrey = Color(0xFF64748B);
  static const Color kTextHint = Color(0xFF94A3B8);
  static const Color kDanger = Color(0xFFEF4444);
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kWarning = Color(0xFFF59E0B);
  static const Color kDivider = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  Future<int?> _resolveRealHastaId() async {
    final candidateId = widget.patient.hastaId;

    final byHastaId = await SupabaseService.client
        .schema('neura')
        .from('hastalar')
        .select('hastaId')
        .eq('hastaId', candidateId)
        .maybeSingle();

    if (byHastaId != null) {
      return byHastaId['hastaId'] as int;
    }

    final byKullaniciId = await SupabaseService.client
        .schema('neura')
        .from('hastalar')
        .select('hastaId')
        .eq('kullaniciId', candidateId)
        .maybeSingle();

    if (byKullaniciId != null) {
      return byKullaniciId['hastaId'] as int;
    }

    return null;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _realHastaId = await _resolveRealHastaId();

      if (_realHastaId == null) {
        if (!mounted) return;
        setState(() {
          _assignedClinicianId = null;
          _assignedClinicianName =
          'Hasta kaydı bulunamadı. Gelen ID: ${widget.patient.hastaId}';
          _isLoading = false;
        });
        return;
      }

      await Future.wait([
        _loadAssignedClinician(),
        _loadPatientRequests(),
        _loadPatientExercises(),
        _loadApprovedMeetings(),
      ]);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _assignedClinicianId = null;
        _assignedClinicianName = 'Hata: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAssignedClinician() async {
    try {
      final clinicianData =
      await _meetingService.getAssignedClinicianForPatient(_realHastaId!);

      if (!mounted) return;

      if (clinicianData == null) {
        setState(() {
          _assignedClinicianId = null;
          _assignedClinicianName =
          'Kayıtlı klinisyen bulunamadı. HastaId: $_realHastaId';
        });
        return;
      }

      final user =
      Map<String, dynamic>.from(clinicianData['kullanicilar'] ?? {});

      final ad = user['ad']?.toString() ?? '';
      final soyad = user['soyad']?.toString() ?? '';
      final fullName = '$ad $soyad'.trim();

      setState(() {
        _assignedClinicianId = clinicianData['klinisyenId'] as int?;
        _assignedClinicianName =
        fullName.isEmpty ? 'Klinisyen' : fullName;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _assignedClinicianId = null;
        _assignedClinicianName = 'Hata: $e';
      });
    }
  }

  Future<void> _loadPatientRequests() async {
    try {
      final requests = await _meetingService.getRequestsByPatient(_realHastaId!);

      if (!mounted) return;

      setState(() {
        _requests = requests;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Talepler yüklenemedi: $e');
    }
  }
  Future<void> _loadPatientExercises() async {
    try {
      final data = await SupabaseService.client
          .schema('neura')
          .from('egzersizAtalari') // tablo adı değişebilir
          .select('hastaId,egzersizAdi,notlar,atamaTarihi')
          .eq('hastaId', _realHastaId!)
          .order('atamaTarihi', ascending: false); // kolon adı değişebilir

      if (!mounted) return;

      setState(() {
        _exercises = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Egzersizler yüklenemedi: $e');
    }
  }
  Future<void> _loadApprovedMeetings() async {
    try {
      final meetings =
      await _meetingService.getMeetingsByPatient(_realHastaId!);

      if (!mounted) return;

      setState(() {
        _approvedMeetings = meetings;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Onaylanan görüşmeler yüklenemedi: $e');
    }
  }

  Future<void> _sendRequest() async {
    if (_realHastaId == null) {
      _showMessage('Hasta kaydı bulunamadı.');
      return;
    }

    if (_assignedClinicianId == null) {
      _showMessage('Bu hasta için kayıtlı klinisyen bulunamadı.');
      return;
    }

    if (_requestController.text.trim().isEmpty) {
      _showMessage('Lütfen talep nedenini yazın.');
      return;
    }

    try {
      setState(() => _isSending = true);

      await _meetingService.createMeetingRequest(
        toplantiId: null,
        hastaId: _realHastaId!,
        klinisyenId: _assignedClinicianId!,
        durum: 'Beklemede',
        talep: _requestController.text.trim(),
      );

      if (!mounted) return;

      _showMessage('Telerehab görüşme talebiniz gönderildi.', success: true);

      setState(() {
        _requestController.clear();
      });

      await _loadPatientRequests();
    } catch (e) {
      _showMessage('Talep gönderilemedi: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  List<Map<String, dynamic>> _requestsForDay(DateTime day) {
    return _requests.where((request) {
      final created = DateTime.tryParse(
        request['olusturmaTarihi']?.toString() ?? '',
      );

      if (created == null) return false;

      return created.year == day.year &&
          created.month == day.month &&
          created.day == day.day;
    }).toList();
  }
  List<Map<String, dynamic>> _exercisesForDay(DateTime day) {
    return _exercises.where((exercise) {
      final created = DateTime.tryParse(
        exercise['atamaTarihi']?.toString() ?? '',
      );

      if (created == null) return false;

      return created.year == day.year &&
          created.month == day.month &&
          created.day == day.day;
    }).toList();
  }
  List<Map<String, dynamic>> _approvedMeetingsForDay(DateTime day) {
    return _approvedMeetings.where((meeting) {
      final created = DateTime.tryParse(
        meeting['baslangicZamani']?.toString() ?? '',
      );

      if (created == null) return false;

      return created.year == day.year &&
          created.month == day.month &&
          created.day == day.day;
    }).toList();
  }

  List<Map<String, dynamic>> _eventsForDay(DateTime day) {
    final requestEvents = _requestsForDay(day).map((item) {
      return {
        ...item,
        'eventType': 'meeting_request',
      };
    }).toList();

    final exerciseEvents = _exercisesForDay(day).map((item) {
      return {
        ...item,
        'eventType': 'exercise',
      };
    }).toList();

    final approvedMeetingEvents =
    _approvedMeetingsForDay(day).map((item) {
      return {
        ...item,
        'eventType': 'approved_meeting',
      };
    }).toList();

    return [
      ...requestEvents,
      ...exerciseEvents,
      ...approvedMeetingEvents,
    ];
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? kSuccess : kDanger,
      ),
    );
  }

  String _formatDate(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return '-';

    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  String _formatTime(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return '-';

    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Onaylandı':
        return kSuccess;
      case 'Reddedildi':
        return kDanger;
      case 'İptal':
      case 'İptal Edildi':
        return kDanger;
      case 'Beklemede':
      default:
        return kWarning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEvents = _eventsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajanda',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
        color: kPrimary,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _calendarCard(),
                    const SizedBox(height: 20),
                    _requestFormCard(),
                    const SizedBox(height: 22),
                    _sectionTitle(
                      Icons.list_alt_outlined,
                      'Seçili Gün Etkinlikleri',
                    ),
                    const SizedBox(height: 12),
                    if (currentEvents.isEmpty)
                      _emptyCard(
                        'Bu gün için gönderilmiş telerehab talebiniz yok.',
                      )
                    else
                      ...currentEvents.map(_eventCard),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasta Ajandası',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.patient.tamAd,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.82),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: TableCalendar<Map<String, dynamic>>(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _eventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Ay',
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(
            color: kTextDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: kPrimary.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: kPrimary,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: kWarning,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: const TextStyle(color: kDanger),
          outsideTextStyle: const TextStyle(color: kTextHint),
        ),
        calendarBuilders: CalendarBuilders<Map<String, dynamic>>(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;

            final hasMeetingRequest =
            events.any((e) => e['eventType'] == 'meeting_request');

            final hasApprovedMeeting =
            events.any((e) => e['eventType'] == 'approved_meeting');

            final hasExercise =
            events.any((e) => e['eventType'] == 'exercise');


            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasMeetingRequest)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: const BoxDecoration(
                        color: kWarning,
                        shape: BoxShape.circle,
                      ),
                    ),

                  if (hasApprovedMeeting)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: const BoxDecoration(
                        color: kSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),

                  if (hasExercise)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _requestFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.video_call_outlined, 'Yeni Görüşme Talebi'),
          const SizedBox(height: 18),
          _fieldLabel('Kayıtlı Klinisyen'),
          _readonlyBox(
            icon: Icons.medical_services_outlined,
            text: _assignedClinicianName,
          ),
          const SizedBox(height: 14),
          _fieldLabel('Talep Nedeni'),
          TextField(
            controller: _requestController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Görüşme talep nedeninizi yazın...',
              hintStyle: const TextStyle(
                color: kTextHint,
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendRequest,
              icon: _isSending
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.send_outlined, color: Colors.white),
              label: Text(
                _isSending ? 'Gönderiliyor...' : 'Talep Gönder',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _eventCard(Map<String, dynamic> event) {
    final type = event['eventType'];

    if (type == 'exercise') {
      return _exerciseCard(event);
    }

    if (type == 'approved_meeting') {
      return _approvedMeetingCard(event);
    }

    return _requestCard(event);
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final status = request['durum']?.toString() ?? 'Beklemede';
    final color = _statusColor(status);
    final talep = request['talep']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(Icons.video_call_outlined, color: color, size: 17),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Telerehab Talebi',
                  style: TextStyle(
                    color: kTextDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _badge(status, color),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            talep,
            style: const TextStyle(
              color: kTextGrey,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: kTextHint),
              const SizedBox(width: 6),
              Text(
                _formatDate(request['olusturmaTarihi']?.toString() ?? ''),
                style: const TextStyle(color: kTextGrey, fontSize: 13),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.access_time_outlined,
                  size: 14, color: kTextHint),
              const SizedBox(width: 6),
              Text(
                _formatTime(request['olusturmaTarihi']?.toString() ?? ''),
                style: const TextStyle(color: kTextGrey, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _exerciseCard(Map<String, dynamic> exercise) {
    final title = exercise['egzersizAdi']?.toString() ??
        exercise['baslik']?.toString() ??
        'Egzersiz Ataması';

    final note = exercise['notlar']?.toString() ??
        exercise['aciklama']?.toString() ??
        'Egzersiz programı atanmış.';

    final rawDate = exercise['atamaTarihi']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor:
                const Color(0xFF8B5CF6).withOpacity(0.12),
                child: const Icon(
                  Icons.fitness_center_outlined,
                  color: Color(0xFF8B5CF6),
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: kTextDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _badge('EGZERSİZ', const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            note,
            style: const TextStyle(
              color: kTextGrey,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: kTextHint,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(rawDate),
                style: const TextStyle(
                  color: kTextGrey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.access_time_outlined,
                size: 14,
                color: kTextHint,
              ),
              const SizedBox(width: 6),
              Text(
                _formatTime(rawDate),
                style: const TextStyle(
                  color: kTextGrey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _approvedMeetingCard(Map<String, dynamic> meeting) {
    final title =
        meeting['baslik']?.toString() ?? 'Onaylanmış Görüşme';

    final note =
        meeting['notlar']?.toString() ?? 'Görüşme planlandı.';

    final rawDate =
        meeting['baslangicZamani']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: kSuccess.withOpacity(0.12),
                child: const Icon(
                  Icons.video_call_outlined,
                  color: kSuccess,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: kTextDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _badge('ONAYLANDI', kSuccess),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            note,
            style: const TextStyle(
              color: kTextGrey,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: kTextHint,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(rawDate),
                style: const TextStyle(
                  color: kTextGrey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.access_time_outlined,
                size: 14,
                color: kTextHint,
              ),
              const SizedBox(width: 6),
              Text(
                _formatTime(rawDate),
                style: const TextStyle(
                  color: kTextGrey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _readonlyBox({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: kTextDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: kPrimary, size: 19),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: kPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          color: kTextGrey,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kTextHint,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kDivider),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}