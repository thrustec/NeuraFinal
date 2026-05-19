import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/meeting_service.dart';
import '../services/supabase_service.dart';

const Color kBackground = Color(0xFFF8F9FC);
const Color kPrimary = Color(0xFF2563EB);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF64748B);
const Color kTextHint = Color(0xFF94A3B8);
const Color kDanger = Color(0xFFDC2626);
const Color kSuccess = Color(0xFF16A34A);
const Color kWarning = Color(0xFFF59E0B);

class TelerehabPatientScreen extends StatefulWidget {
  const TelerehabPatientScreen({super.key});

  @override
  State<TelerehabPatientScreen> createState() =>
      _TelerehabPatientScreenState();
}

class _TelerehabPatientScreenState extends State<TelerehabPatientScreen> {
  final MeetingService meetingService = MeetingService();

  bool isLoading = true;

  int? currentPatientId;

  List<Map<String, dynamic>> meetings = [];
  List<Map<String, dynamic>> requests = [];

  String selectedFilter = 'Mevcut';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadPageData();
    });
  }

  Future<int?> resolveCurrentPatientId() async {
    final auth = context.read<AuthProvider>();
    final kullaniciId = int.tryParse(auth.user?.id ?? '');

    if (kullaniciId == null) return null;

    final patient = await SupabaseService.client
        .schema('neura')
        .from('hastalar')
        .select('hastaId')
        .eq('kullaniciId', kullaniciId)
        .maybeSingle();

    if (patient == null) return null;

    return patient['hastaId'] as int;
  }

  Future<void> loadPageData() async {
    setState(() => isLoading = true);

    try {
      currentPatientId = await resolveCurrentPatientId();

      if (currentPatientId == null) {
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hasta kaydı bulunamadı.')),
        );
        return;
      }

      final fetchedMeetings =
      await meetingService.getMeetingsByPatient(currentPatientId!);

      final fetchedRequests =
      await meetingService.getRequestsByPatient(currentPatientId!);

      if (!mounted) return;

      setState(() {
        meetings = fetchedMeetings;
        requests = fetchedRequests;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler yüklenemedi: $e')),
      );
    }
  }

  DateTime? effectiveMeetingEnd(Map<String, dynamic> meeting) {
    final start = DateTime.tryParse(
      meeting['baslangicZamani']?.toString() ?? '',
    );

    if (start == null) return null;

    return start.add(const Duration(minutes: 40));
  }

  List<Map<String, dynamic>> filteredMeetings() {
    final now = DateTime.now();

    if (selectedFilter == 'Beklemede') {
      return requests.where((r) => r['durum'] == 'Beklemede').toList();
    }

    if (selectedFilter == 'Reddedildi') {
      return requests.where((r) => r['durum'] == 'Reddedildi').toList();
    }

    if (selectedFilter == 'Geçmiş') {
      return meetings.where((m) {
        final end = effectiveMeetingEnd(m);
        if (end == null) return false;

        return end.isBefore(now) && m['durum'] != 'İptal Edildi';
      }).toList();
    }

    if (selectedFilter == 'Bugünkü') {
      return meetings.where((m) {
        final start =
        DateTime.tryParse(m['baslangicZamani']?.toString() ?? '');
        final end = effectiveMeetingEnd(m);

        if (start == null || end == null) return false;

        return start.year == now.year &&
            start.month == now.month &&
            start.day == now.day &&
            end.isAfter(now) &&
            m['durum'] != 'İptal Edildi';
      }).toList();
    }

    return meetings.where((m) {
      final end = effectiveMeetingEnd(m);
      if (end == null) return false;

      return end.isAfter(now) && m['durum'] != 'İptal Edildi';
    }).toList();
  }

  bool canJoinMeeting(Map<String, dynamic> meeting) {
    final start = DateTime.tryParse(
      meeting['baslangicZamani']?.toString() ?? '',
    );

    final end = effectiveMeetingEnd(meeting);

    if (start == null || end == null) return false;

    final now = DateTime.now();

    return now.isAfter(start) &&
        now.isBefore(end) &&
        meeting['baslatildimi'] == true;
  }

  Future<void> joinMeeting(Map<String, dynamic> meeting) async {
    final zoomLink = meeting['zoomlink']?.toString().trim() ?? '';

    if (zoomLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zoom linki bulunamadı.')),
      );
      return;
    }

    final opened = await launchUrl(
      Uri.parse(zoomLink),
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toplantı açılamadı.')),
      );
    }
  }

  String formatDate(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return '-';

    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  String formatTimeFromDate(DateTime? date) {
    if (date == null) return '-';

    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String formatTime(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return '-';

    return formatTimeFromDate(d);
  }

  String fullNameFromUser(dynamic user) {
    if (user is! Map) return '-';

    final ad = user['ad']?.toString() ?? '';
    final soyad = user['soyad']?.toString() ?? '';
    final full = '$ad $soyad'.trim();

    return full.isEmpty ? '-' : full;
  }

  Widget filterChip(String label) {
    final selected = selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            selectedFilter = label;
          });
        },
        selectedColor: kPrimary,
        backgroundColor: const Color(0xFFE2E8F0),
        labelStyle: TextStyle(
          color: selected ? Colors.white : kTextDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget requestCard(Map<String, dynamic> request) {
    final durum = request['durum']?.toString() ?? 'Beklemede';
    final talep = request['talep']?.toString() ?? '-';

    final isRejected = durum == 'Reddedildi';
    final color = isRejected ? kDanger : kWarning;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(
                  isRejected ? Icons.close : Icons.hourglass_bottom,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Telerehab Talebi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: kTextDark,
                  ),
                ),
              ),
              badge(durum, color),
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
        ],
      ),
    );
  }

  Widget meetingInfoBox({
    required IconData icon,
    required String title,
    required String name,
    required String idText,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  idText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: kTextGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget meetingCard(Map<String, dynamic> meeting) {
    final baslik = meeting['baslik']?.toString() ?? 'Telerehabilitasyon';
    final startRaw = meeting['baslangicZamani']?.toString();
    final startDate = DateTime.tryParse(startRaw ?? '');
    final endDate = effectiveMeetingEnd(meeting);
    final durum = meeting['durum']?.toString() ?? '';

    final hastaBilgisi = meeting['hastaBilgisi'];
    final klinisyenBilgisi = meeting['klinisyenBilgisi'];

    final hastaMap =
    hastaBilgisi is Map ? Map<String, dynamic>.from(hastaBilgisi) : null;
    final klinisyenMap = klinisyenBilgisi is Map
        ? Map<String, dynamic>.from(klinisyenBilgisi)
        : null;

    final hastaId = hastaMap?['hastaId'] ?? meeting['hastaId'] ?? '-';
    final hastaAdi = fullNameFromUser(hastaMap?['kullanicilar']);

    final klinisyenId =
        klinisyenMap?['klinisyenId'] ?? meeting['klinisyenId'] ?? '-';

    final unvan = klinisyenMap?['unvan']?.toString().trim() ?? '';
    final klinisyenAdiRaw =
    fullNameFromUser(klinisyenMap?['kullanicilar']);
    final klinisyenAdi = unvan.isNotEmpty && klinisyenAdiRaw != '-'
        ? '$unvan $klinisyenAdiRaw'
        : klinisyenAdiRaw;

    final joinable = canJoinMeeting(meeting);

    final isPast = endDate?.isBefore(DateTime.now()) == true;

    Color badgeColor;
    String badgeText;

    if (durum == 'İptal Edildi') {
      badgeColor = kDanger;
      badgeText = 'İptal';
    } else if (isPast) {
      badgeColor = kTextHint;
      badgeText = 'Geçmiş';
    } else if (joinable) {
      badgeColor = kSuccess;
      badgeText = 'Katılabilir';
    } else {
      badgeColor = kWarning;
      badgeText = 'Bekleniyor';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: badgeColor.withOpacity(0.1),
                child: Icon(
                  Icons.video_call,
                  color: badgeColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  baslik,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: kTextDark,
                  ),
                ),
              ),
              badge(badgeText, badgeColor),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: kTextHint,
              ),
              const SizedBox(width: 6),
              Text(
                startRaw == null ? '-' : formatDate(startRaw),
                style: const TextStyle(color: kTextGrey),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.access_time_outlined,
                size: 14,
                color: kTextHint,
              ),
              const SizedBox(width: 6),
              Text(
                startDate == null ? '-' : formatTimeFromDate(startDate),
                style: const TextStyle(color: kTextGrey),
              ),
              const SizedBox(width: 4),
              Text(
                '- ${formatTimeFromDate(endDate)}',
                style: const TextStyle(color: kTextGrey),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: meetingInfoBox(
                  icon: Icons.person_outline,
                  title: 'HASTA',
                  name: hastaAdi,
                  idText: 'ID: $hastaId',
                  color: kPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: meetingInfoBox(
                  icon: Icons.medical_services_outlined,
                  title: 'KLİNİSYEN',
                  name: klinisyenAdi,
                  idText: 'ID: $klinisyenId',
                  color: const Color(0xFF0F766E),
                ),
              ),
            ],
          ),

          if (!isPast && durum != 'İptal Edildi') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: joinable ? () => joinMeeting(meeting) : null,
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text(
                  'Görüşmeye Katıl',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredMeetings();
    final showingRequests =
        selectedFilter == 'Beklemede' || selectedFilter == 'Reddedildi';

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: kTextDark,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Telerehabilitasyon',
          style: TextStyle(
            color: kTextDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: kPrimary),
      )
          : RefreshIndicator(
        onRefresh: loadPageData,
        color: kPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Toplantılarım',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    filterChip('Mevcut'),
                    filterChip('Bugün'),
                    filterChip('Reddedildi'),
                    filterChip('Beklemede'),
                    filterChip('Geçmiş'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: cardDecoration(),
                  child: const Center(
                    child: Text(
                      'Kayıt bulunamadı.',
                      style: TextStyle(color: kTextHint),
                    ),
                  ),
                )
              else if (showingRequests)
                ...filtered.map(requestCard)
              else
                ...filtered.map(meetingCard),
            ],
          ),
        ),
      ),
    );
  }
}