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
  State<TelerehabPatientScreen> createState() => _TelerehabPatientScreenState();
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
        final end = DateTime.tryParse(m['bitisZamani']?.toString() ?? '');
        if (end == null) return false;

        return end.isBefore(now) && m['durum'] != 'İptal Edildi';
      }).toList();
    }

    if (selectedFilter == 'Bugünkü') {
      return meetings.where((m) {
        final start = DateTime.tryParse(m['baslangicZamani']?.toString() ?? '');
        final end = DateTime.tryParse(m['bitisZamani']?.toString() ?? '');

        if (start == null || end == null) return false;

        return start.year == now.year &&
            start.month == now.month &&
            start.day == now.day &&
            end.isAfter(now) &&
            m['durum'] != 'İptal Edildi';
      }).toList();
    }

    return meetings.where((m) {
      final end = DateTime.tryParse(m['bitisZamani']?.toString() ?? '');
      if (end == null) return false;

      return end.isAfter(now) && m['durum'] != 'İptal Edildi';
    }).toList();
  }

  bool canJoinMeeting(Map<String, dynamic> meeting) {
    final start = DateTime.tryParse(
      meeting['baslangicZamani']?.toString() ?? '',
    );
    final end = DateTime.tryParse(
      meeting['bitisZamani']?.toString() ?? '',
    );

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

  String formatTime(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return '-';

    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
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

  Widget meetingCard(Map<String, dynamic> meeting) {
    final baslik = meeting['baslik']?.toString() ?? 'Telerehabilitasyon';
    final start = meeting['baslangicZamani']?.toString();
    final end = meeting['bitisZamani']?.toString();
    final durum = meeting['durum']?.toString() ?? '';

    final joinable = canJoinMeeting(meeting);

    final isPast = end != null &&
        DateTime.tryParse(end)?.isBefore(DateTime.now()) == true;

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
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: kTextHint),
              const SizedBox(width: 6),
              Text(
                start == null ? '-' : formatDate(start),
                style: const TextStyle(color: kTextGrey),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time_outlined,
                  size: 14, color: kTextHint),
              const SizedBox(width: 6),
              Text(
                start == null ? '-' : formatTime(start),
                style: const TextStyle(color: kTextGrey),
              ),
              if (end != null) ...[
                const SizedBox(width: 4),
                Text(
                  '- ${formatTime(end)}',
                  style: const TextStyle(color: kTextGrey),
                ),
              ],
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
                    filterChip('Bugünkü'),
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