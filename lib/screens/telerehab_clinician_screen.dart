import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/meeting_service.dart';

const Color kBackground = Color(0xFFF8F9FC);
const Color kPrimary = Color(0xFF22C55E);
const Color kDarkGreen = Color(0xFF16A34A);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF64748B);
const Color kTextHint = Color(0xFF94A3B8);
const Color kDanger = Color(0xFFDC2626);
const Color kWarning = Color(0xFFF59E0B);

class TelerehabClinicianScreen extends StatefulWidget {
  const TelerehabClinicianScreen({super.key});

  @override
  State<TelerehabClinicianScreen> createState() =>
      _TelerehabClinicianScreenState();
}

class _TelerehabClinicianScreenState extends State<TelerehabClinicianScreen> {
  final MeetingService _meetingService = MeetingService();

  bool _isLoading = true;
  int? _currentClinicianId;

  List<Map<String, dynamic>> _meetings = [];
  String _selectedFilter = 'Mevcut';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final kullaniciId = int.tryParse(auth.user?.id ?? '');

      if (kullaniciId == null) {
        _showMessage('Klinisyen bilgisi alınamadı.');
        setState(() => _isLoading = false);
        return;
      }

      try {
        final clinician =
        await _meetingService.getClinicianByUserId(kullaniciId);

        if (clinician == null) {
          _showMessage('Klinisyen kaydı bulunamadı.');
          setState(() => _isLoading = false);
          return;
        }

        _currentClinicianId = clinician['klinisyenId'] as int;
        await _loadMeetings();
      } catch (e) {
        _showMessage('Klinisyen yüklenemedi: $e');
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _loadMeetings() async {
    if (_currentClinicianId == null) return;

    setState(() => _isLoading = true);

    try {
      final meetings = await _meetingService.getMeetingsByClinician(
        _currentClinicianId!,
      );

      if (!mounted) return;

      setState(() {
        _meetings = meetings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Toplantılar yüklenemedi: $e');
    }
  }

  Future<void> _startMeeting(Map<String, dynamic> meeting) async {
    final int toplantiId = meeting['toplantiId'] as int;
    final String? zoomLink =
    meeting['zoomlink']?.toString().trim().isEmpty == true
        ? null
        : meeting['zoomlink']?.toString().trim();

    final DateTime? startTime = DateTime.tryParse(
      meeting['baslangicZamani']?.toString() ?? '',
    );

    if (startTime == null) {
      _showMessage('Toplantı zamanı okunamadı.');
      return;
    }

    if (DateTime.now().isBefore(startTime)) {
      _showMessage('Görüşme zamanı henüz gelmedi.');
      return;
    }

    if (zoomLink == null || zoomLink.isEmpty) {
      _showMessage('Bu toplantıya ait Zoom linki bulunamadı.');
      return;
    }

    try {
      await _meetingService.startMeeting(toplantiId);

      final uri = Uri.parse(zoomLink);
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        _showMessage('Zoom bağlantısı açılamadı.');
      }

      await _loadMeetings();
    } catch (e) {
      _showMessage('Görüşme başlatılamadı: $e');
    }
  }

  Future<void> _cancelMeeting(Map<String, dynamic> meeting) async {
    final int toplantiId = meeting['toplantiId'] as int;

    try {
      await _meetingService.cancelMeeting(toplantiId);
      _showMessage('Toplantı iptal edildi.', success: true);
      await _loadMeetings();
    } catch (e) {
      _showMessage('Toplantı iptal edilemedi: $e');
    }
  }

  Future<void> _postponeMeeting(Map<String, dynamic> meeting) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Toplantıyı Ertele'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      selectedDate == null
                          ? 'Yeni tarih seç'
                          : _formatDate(selectedDate!.toIso8601String()),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );

                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(
                      selectedTime == null
                          ? 'Yeni saat seç'
                          : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (selectedDate == null || selectedTime == null) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || selectedDate == null || selectedTime == null) return;

    final newStart = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final newEnd = newStart.add(const Duration(hours: 1));

    try {
      await _meetingService.postponeMeeting(
        toplantiId: meeting['toplantiId'] as int,
        yeniBaslangicZamani: newStart,
        yeniBitisZamani: newEnd,
      );

      _showMessage('Toplantı ertelendi.', success: true);
      await _loadMeetings();
    } catch (e) {
      _showMessage('Toplantı ertelenemedi: $e');
    }
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? kPrimary : Colors.red,
      ),
    );
  }

  String _getPatientName(Map<String, dynamic> meeting) {
    final hasta = meeting['hastalar'];
    final user = hasta is Map ? hasta['kullanicilar'] : null;

    if (user is Map) {
      final ad = user['ad']?.toString() ?? '';
      final soyad = user['soyad']?.toString() ?? '';
      final fullName = '$ad $soyad'.trim();

      if (fullName.isNotEmpty) return fullName;
    }

    return 'Hasta';
  }

  bool _isCancelled(Map<String, dynamic> meeting) {
    final durum = meeting['durum']?.toString() ?? '';
    return durum == 'İptal Edildi';
  }

  bool _isPast(Map<String, dynamic> meeting) {
    final end = DateTime.tryParse(
      meeting['bitisZamani']?.toString() ?? '',
    );

    if (end == null) return false;

    return end.isBefore(DateTime.now());
  }

  bool _canStart(Map<String, dynamic> meeting) {
    if (_isCancelled(meeting)) return false;
    if (_isPast(meeting)) return false;

    final start = DateTime.tryParse(
      meeting['baslangicZamani']?.toString() ?? '',
    );

    final end = DateTime.tryParse(
      meeting['bitisZamani']?.toString() ?? '',
    );

    if (start == null || end == null) return false;

    final now = DateTime.now();

    return (now.isAfter(start) || now.isAtSameMomentAs(start)) &&
        (now.isBefore(end) || now.isAtSameMomentAs(end));
  }

  List<Map<String, dynamic>> _filteredMeetings() {
    final now = DateTime.now();

    if (_selectedFilter == 'İptal Edilmiş') {
      return _meetings.where((m) {
        return m['durum']?.toString() == 'İptal Edildi';
      }).toList();
    }

    if (_selectedFilter == 'Ertelenmiş') {
      return _meetings.where((m) {
        return m['durum']?.toString() == 'Ertelendi';
      }).toList();
    }

    if (_selectedFilter == 'Geçmiş') {
      return _meetings.where((m) {
        final end = DateTime.tryParse(m['bitisZamani']?.toString() ?? '');
        if (end == null) return false;

        return end.isBefore(now) &&
            m['durum']?.toString() != 'İptal Edildi';
      }).toList();
    }

    if (_selectedFilter == 'Bugünkü') {
      return _meetings.where((m) {
        final start = DateTime.tryParse(
          m['baslangicZamani']?.toString() ?? '',
        );

        final end = DateTime.tryParse(
          m['bitisZamani']?.toString() ?? '',
        );

        if (start == null || end == null) return false;

        return start.year == now.year &&
            start.month == now.month &&
            start.day == now.day &&
            end.isAfter(now) &&
            m['durum']?.toString() != 'İptal Edildi';
      }).toList();
    }

    return _meetings.where((m) {
      final end = DateTime.tryParse(m['bitisZamani']?.toString() ?? '');
      if (end == null) return false;

      return end.isAfter(now) &&
          m['durum']?.toString() != 'İptal Edildi';
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = auth.user?.displayName ?? 'Klinisyen';
    final filteredMeetings = _filteredMeetings();

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
            color: kPrimary,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
        onRefresh: _loadMeetings,
        color: kPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _welcomeCard(displayName),
              const SizedBox(height: 20),
              _sectionTitle(
                Icons.video_camera_front_outlined,
                'Telerehab Görüşmeleri',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('Mevcut'),
                    _filterChip('Bugünkü'),
                    _filterChip('Ertelenmiş'),
                    _filterChip('İptal Edilmiş'),
                    _filterChip('Geçmiş'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (filteredMeetings.isEmpty)
                _emptyCard('Bu filtreye uygun telerehab görüşmesi yok.')
              else
                ...filteredMeetings.map(_meetingCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _welcomeCard(String displayName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, kDarkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.video_call_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Görüşme Yönetimi',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
            color: kDarkGreen,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _selectedFilter = label;
          });
        },
        selectedColor: kPrimary,
        backgroundColor: const Color(0xFFE2E8F0),
        labelStyle: TextStyle(
          color: selected ? Colors.white : kTextDark,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }

  Widget _meetingCard(Map<String, dynamic> meeting) {
    final patientName = _getPatientName(meeting);
    final baslik = meeting['baslik']?.toString() ?? 'Telerehabilitasyon';
    final start = meeting['baslangicZamani']?.toString();
    final end = meeting['bitisZamani']?.toString();
    final zoomLink = meeting['zoomlink']?.toString();
    final started = meeting['baslatildimi'] == true;
    final cancelled = _isCancelled(meeting);
    final past = _isPast(meeting);
    final canStart = _canStart(meeting);

    Color statusColor;
    String statusText;

    if (past && !cancelled) {
      statusColor = kTextHint;
      statusText = 'Geçmiş';
    } else if (cancelled) {
      statusColor = kDanger;
      statusText = 'İptal Edildi';
    } else if (started) {
      statusColor = kPrimary;
      statusText = 'Başlatıldı';
    } else if (canStart) {
      statusColor = kWarning;
      statusText = 'Başlatılabilir';
    } else {
      statusColor = kTextHint;
      statusText = 'Zamanı Bekleniyor';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: statusColor.withOpacity(0.12),
                child: Icon(Icons.person, size: 17, color: statusColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  patientName,
                  style: const TextStyle(
                    color: kTextDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusBadge(statusText, statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            baslik,
            style: const TextStyle(
              color: kTextDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
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
                start == null ? '-' : _formatDate(start),
                style: const TextStyle(color: kTextGrey, fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.access_time_outlined,
                size: 14,
                color: kTextHint,
              ),
              const SizedBox(width: 6),
              Text(
                start == null ? '-' : _formatTime(start),
                style: const TextStyle(color: kTextGrey, fontSize: 13),
              ),
              if (end != null) ...[
                const SizedBox(width: 4),
                Text(
                  '- ${_formatTime(end)}',
                  style: const TextStyle(color: kTextGrey, fontSize: 13),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                zoomLink == null || zoomLink.trim().isEmpty
                    ? Icons.link_off
                    : Icons.link,
                size: 14,
                color: kTextHint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  zoomLink == null || zoomLink.trim().isEmpty
                      ? 'Zoom linki eklenmemiş'
                      : 'Zoom linki hazır',
                  style: const TextStyle(color: kTextGrey, fontSize: 13),
                ),
              ),
            ],
          ),
          if (!past) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canStart && !cancelled
                        ? () => _startMeeting(meeting)
                        : null,
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      'Görüşmeyi Başlat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                    cancelled ? null : () => _postponeMeeting(meeting),
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('Ertele'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kWarning,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                    cancelled ? null : () => _cancelMeeting(meeting),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('İptal Et'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kDanger,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 10,
        ),
      ],
    );
  }
}