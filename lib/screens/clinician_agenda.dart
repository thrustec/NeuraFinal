import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/meeting_service.dart';

class ClinicianAgenda extends StatefulWidget {
  const ClinicianAgenda({super.key});

  @override
  State<ClinicianAgenda> createState() => _ClinicianAgendaState();
}

class _ClinicianAgendaState extends State<ClinicianAgenda> {
  static const Color _green = Color(0xFF22C55E);
  static const Color _darkGreen = Color(0xFF16A34A);
  static const Color _background = Color(0xFFF8F9FC);

  final MeetingService _meetingService = MeetingService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  List<Map<String, dynamic>> _meetings = [];
  List<Map<String, dynamic>> _pendingRequests = [];

  String? _selectedPatientId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _repeat = 'Tek Sefer';

  bool _isLoading = true;
  int? _currentClinicianId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final kullaniciId = int.tryParse(auth.user?.id ?? '');

      if (kullaniciId == null) {
        _showMessage('Klinisyen kullanıcı bilgisi alınamadı.');
        setState(() => _isLoading = false);
        return;
      }

      try {
        final clinician = await _meetingService.getClinicianByUserId(kullaniciId);

        if (clinician == null) {
          _showMessage('Bu kullanıcıya ait klinisyen kaydı bulunamadı.');
          setState(() => _isLoading = false);
          return;
        }

        _currentClinicianId = clinician['klinisyenId'] as int;
        await _loadData();
      } catch (e) {
        _showMessage('Klinisyen bilgisi yüklenemedi: $e');
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_currentClinicianId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    await Future.wait([
      _loadPatients(),
      _loadMeetings(),
      _loadPendingRequests(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await _meetingService.getPatientsByClinician(
        _currentClinicianId!,
      );

      final mappedPatients = patients.map<Map<String, dynamic>>((p) {
        final user = p['kullanicilar'];

        final name = user != null
            ? '${user['ad'] ?? ''} ${user['soyad'] ?? ''}'.trim()
            : 'Hasta ${p['hastaId']}';

        return {
          'id': p['hastaId'].toString(),
          'name': name.isEmpty ? 'Hasta ${p['hastaId']}' : name,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _patients = mappedPatients;
        _filteredPatients = mappedPatients;
      });
    } catch (e) {
      _showMessage('Hastalar yüklenemedi: $e');
    }
  }

  Future<void> _loadMeetings() async {
    try {
      final meetings = await _meetingService.getMeetingsByClinician(
        _currentClinicianId!,
      );

      if (!mounted) return;

      setState(() {
        _meetings = meetings;
      });
    } catch (e) {
      _showMessage('Randevular yüklenemedi: $e');
    }
  }

  Future<void> _loadPendingRequests() async {
    try {
      final requests = await _meetingService.getPendingRequestsByClinician(
        _currentClinicianId!,
      );

      if (!mounted) return;

      setState(() {
        _pendingRequests = requests;
      });
    } catch (e) {
      _showMessage('Talepler yüklenemedi: $e');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _green),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _green),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _createMeeting() async {
    if (_currentClinicianId == null) {
      _showMessage('Klinisyen bilgisi bulunamadı.');
      return;
    }

    if (_selectedPatientId == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      _showMessage('Lütfen hasta, tarih ve saat seçin.');
      return;
    }

    final startTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final endTime = startTime.add(const Duration(hours: 1));

    try {
      await _meetingService.createMeeting(
        hastaId: int.parse(_selectedPatientId!),
        klinisyenId: _currentClinicianId!,
        baslik: 'Telerehabilitasyon Randevusu',
        baslangicZamani: startTime,
        bitisZamani: endTime,
        notlar: _repeat,
      );

      _showMessage('Randevu başarıyla oluşturuldu.', success: true);

      setState(() {
        _selectedPatientId = null;
        _selectedDate = null;
        _selectedTime = null;
        _repeat = 'Tek Sefer';
        _searchController.clear();
        _filteredPatients = _patients;
      });

      await _loadMeetings();
    } catch (e) {
      _showMessage('Randevu oluşturulamadı: $e');
    }
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Talebi Onayla'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bu talep için randevu tarih ve saatini seçin.'),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      selectedDate == null
                          ? 'Tarih seç'
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
                          ? 'Saat seç'
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
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (selectedDate == null || selectedTime == null) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Onayla'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || selectedDate == null || selectedTime == null) return;

    final startTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final endTime = startTime.add(const Duration(hours: 1));

    try {
      await _meetingService.approveMeetingRequest(
        toplantiIstegiId: request['toplantiIstegiId'] as int,
        hastaId: request['hastaId'] as int,
        klinisyenId: request['klinisyenId'] as int,
        baslik: 'Telerehabilitasyon Randevusu',
        baslangicZamani: startTime,
        bitisZamani: endTime,
        notlar: request['talep']?.toString(),
      );

      _showMessage('Talep onaylandı ve randevu oluşturuldu.', success: true);

      await _loadData();
    } catch (e) {
      _showMessage('Talep onaylanamadı: $e');
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    try {
      await _meetingService.rejectMeetingRequest(
        toplantiIstegiId: request['toplantiIstegiId'] as int,
      );

      _showMessage('Talep reddedildi.', success: true);

      await _loadPendingRequests();
    } catch (e) {
      _showMessage('Talep reddedilemedi: $e');
    }
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? _green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Klinisyen Ajandası',
          style: TextStyle(
            color: _green,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _green,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _newPlanCard(),
                const SizedBox(height: 24),
                _pendingRequestsSection(),
                const SizedBox(height: 24),
                _meetingsSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _newPlanCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.add_task, 'Yeni Plan Oluştur'),
          const SizedBox(height: 18),
          _label(Icons.person, 'Hasta'),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _filteredPatients = _patients.where((p) {
                  final name = p['name'].toString().toLowerCase();
                  final id = p['id'].toString();
                  final query = value.toLowerCase();
                  return name.contains(query) || id.contains(query);
                }).toList();
              });
            },
            decoration: _inputDecoration('Hasta adı veya ID yazın...'),
          ),
          const SizedBox(height: 8),
          _patientDropdown(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _dateBox()),
              const SizedBox(width: 12),
              Expanded(child: _timeBox()),
            ],
          ),
          const SizedBox(height: 18),
          _label(Icons.repeat, 'Tekrar'),
          const SizedBox(height: 8),
          _repeatDropdown(),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _createMeeting,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text(
                'Plan Oluştur',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
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

  Widget _patientDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _inputBoxDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPatientId,
          hint: const Text(
            'Bir hasta seçin',
            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
          isExpanded: true,
          items: _filteredPatients.map((p) {
            return DropdownMenuItem<String>(
              value: p['id'].toString(),
              child: Text(p['name'].toString()),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedPatientId = val;
            });
          },
        ),
      ),
    );
  }

  Widget _repeatDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _inputBoxDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _repeat,
          isExpanded: true,
          items: ['Tek Sefer', 'Haftalık', 'Aylık']
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (val) => setState(() => _repeat = val ?? 'Tek Sefer'),
        ),
      ),
    );
  }

  Widget _dateBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(Icons.calendar_today, 'Tarih'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: _pickerBox(
            icon: Icons.calendar_today_outlined,
            text: _selectedDate == null
                ? 'Tarih seçin'
                : '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}',
            selected: _selectedDate != null,
          ),
        ),
      ],
    );
  }

  Widget _timeBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(Icons.access_time, 'Saat'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickTime,
          child: _pickerBox(
            icon: Icons.access_time_outlined,
            text: _selectedTime == null
                ? 'Saat seçin'
                : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
            selected: _selectedTime != null,
          ),
        ),
      ],
    );
  }

  Widget _pendingRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.inbox_outlined, 'Hastadan Gelen Talepler'),
        const SizedBox(height: 12),
        if (_pendingRequests.isEmpty)
          _emptyCard('Bekleyen talep bulunmuyor.')
        else
          ..._pendingRequests.map(_requestCard),
      ],
    );
  }

  Widget _meetingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.event_available, 'Mevcut Randevular'),
        const SizedBox(height: 12),
        if (_meetings.isEmpty)
          _emptyCard('Henüz randevu yok.')
        else
          ..._meetings.map(_meetingCard),
      ],
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final patientName = _getPatientName(request);
    final talep = request['talep']?.toString() ?? 'Talep nedeni belirtilmedi.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(patientName, 'Beklemede', Colors.orange),
          const SizedBox(height: 10),
          Text(
            talep,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveRequest(request),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'Onayla',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _rejectRequest(request),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    'Reddet',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meetingCard(Map<String, dynamic> meeting) {
    final patientName = _getPatientName(meeting);
    final start = meeting['baslangicZamani']?.toString();
    final baslik = meeting['baslik']?.toString() ?? 'Randevu';
    final durum = meeting['durum']?.toString() ?? 'Planlandı';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(patientName, durum, _green),
          const SizedBox(height: 10),
          Text(
            baslik,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                start == null ? '-' : _formatDate(start),
                style:
                const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.access_time,
                  size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                start == null ? '-' : _formatTime(start),
                style:
                const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardHeader(String title, String status, Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.person, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _green, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _darkGreen,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _label(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _pickerBox({
    required IconData icon,
    required String text,
    required bool selected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: _inputBoxDecoration(),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                selected ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  String _getPatientName(Map<String, dynamic> data) {
    final hasta = data['hastalar'];
    final user = hasta is Map ? hasta['kullanicilar'] : null;

    if (user is Map) {
      final ad = user['ad']?.toString() ?? '';
      final soyad = user['soyad']?.toString() ?? '';
      final fullName = '$ad $soyad'.trim();

      if (fullName.isNotEmpty) return fullName;
    }

    return 'Hasta';
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFEFF6FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  BoxDecoration _inputBoxDecoration() {
    return BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(14),
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