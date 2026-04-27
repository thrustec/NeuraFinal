import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/agenda_service.dart';
import '../bbb_call_screen.dart';

class ClinicianAgenda extends StatefulWidget {
  const ClinicianAgenda({super.key});

  @override
  State<ClinicianAgenda> createState() => _ClinicianAgendaState();
}

class _ClinicianAgendaState extends State<ClinicianAgenda> {
  static const Color _green = Color(0xFF0F766E);
  static const Color kBackground = Color(0xFFF8F9FC);

  final AgendaService _agendaService = AgendaService();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedPatientId;
  String? _selectedPatientName;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _repeat = 'Tek Sefer';

  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  List<Map<String, dynamic>> _appointments = [];

  bool _isLoading = true;
  int _currentClinicianUserId = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final parsed = int.tryParse(auth.user?.id ?? '');

      if (parsed != null) {
        _currentClinicianUserId = parsed;
      }

      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadPatients(),
      _loadAppointments(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await _agendaService.getPatientsForDropdown();

      if (!mounted) return;

      setState(() {
        _patients = patients;
        _filteredPatients = patients;
      });
    } catch (e) {
      debugPrint('Patients error: $e');
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final appointments = await _agendaService.getClinicianMeetings(
        klinisyenId: _currentClinicianUserId,
      );

      if (!mounted) return;

      setState(() {
        _appointments = appointments;
      });
    } catch (e) {
      debugPrint('Appointments error: $e');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _green),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _green),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _createPlan() async {
    if (_selectedPatientId == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      await _agendaService.createClinicianMeeting(
        hastaId: int.parse(_selectedPatientId!),
        klinisyenId: _currentClinicianUserId,
        baslangicZamani: dt,
        baslik: 'Randevu',
        notlar: _repeat,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Randevu başarıyla oluşturuldu!'),
          backgroundColor: _green,
        ),
      );

      setState(() {
        _selectedPatientId = null;
        _selectedPatientName = null;
        _selectedDate = null;
        _selectedTime = null;
        _searchController.clear();
        _filteredPatients = _patients;
      });

      await _loadAppointments();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu oluşturulamadı: $e')),
      );
    }
  }

  Future<void> _updateAppointmentStatus(int index, bool approved) async {
    final apt = _appointments[index];
    final toplantiId = int.parse(apt['id'].toString());
    final durum = approved ? 'Onaylandı' : 'İptal';

    try {
      await _agendaService.updateMeetingStatus(
        toplantiId: toplantiId,
        durum: durum,
      );

      if (!mounted) return;

      setState(() {
        _appointments[index]['approved'] = approved;
        _appointments[index]['status'] = durum;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Durum güncellenemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
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
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _newPlanCard(),
              const SizedBox(height: 32),
              _appointmentsHeader(),
              const SizedBox(height: 12),
              if (_appointments.isEmpty) _emptyAppointmentsCard(),
              ..._appointments.asMap().entries.map((entry) {
                return _appointmentCard(entry.key, entry.value);
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newPlanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.add_task, color: _green, size: 20),
              SizedBox(width: 8),
              Text(
                'Yeni Plan Oluştur',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionLabel(icon: Icons.person, label: 'Hasta'),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _filteredPatients = _patients
                    .where(
                      (p) =>
                  (p['name'] as String)
                      .toLowerCase()
                      .contains(value.toLowerCase()) ||
                      (p['id'] as String).contains(value),
                )
                    .toList();

                if (_selectedPatientId != null) {
                  final exists = _filteredPatients.any(
                        (p) => p['id'] == _selectedPatientId,
                  );

                  if (!exists) {
                    _selectedPatientId = null;
                    _selectedPatientName = null;
                  }
                }
              });
            },
            decoration: _inputDecoration('Hasta adı giriniz'),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
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
                    child: Text(p['name'] as String),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedPatientId = val;
                    _selectedPatientName = _filteredPatients.firstWhere(
                          (p) => p['id'] == val,
                    )['name'] as String?;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _dateBox()),
              const SizedBox(width: 12),
              Expanded(child: _timeBox()),
            ],
          ),
          const SizedBox(height: 20),
          _SectionLabel(icon: Icons.repeat, label: 'Tekrar'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _repeat,
                isExpanded: true,
                items: ['Tek Sefer', 'Haftalık', 'Aylık']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setState(() => _repeat = val!),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _createPlan,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text(
                'Randevu Oluştur',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(icon: Icons.calendar_today, label: 'Tarih'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: _pickerBox(
            icon: Icons.calendar_today_outlined,
            text: _selectedDate == null
                ? 'Seçiniz'
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
        _SectionLabel(icon: Icons.access_time, label: 'Saat'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickTime,
          child: _pickerBox(
            icon: Icons.access_time_outlined,
            text: _selectedTime == null
                ? 'Seçiniz'
                : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
            selected: _selectedTime != null,
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
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointmentsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'MEVCUT RANDEVULAR',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
        GestureDetector(
          onTap: _loadAppointments,
          child: const Icon(Icons.refresh, color: _green, size: 20),
        ),
      ],
    );
  }

  Widget _emptyAppointmentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: _cardDecoration(),
      child: const Center(
        child: Text(
          'Henüz randevu yok.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  Widget _appointmentCard(int index, Map<String, dynamic> apt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _green.withOpacity(0.1),
                child: const Icon(Icons.person, size: 16, color: _green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  apt['patient'] ?? 'Hasta',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  apt['diagnosis'] ?? 'Randevu',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                apt['date'] ?? '-',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.access_time_outlined,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                apt['time'] ?? '-',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BbbCallScreen(
                      toplantiId: int.parse(apt['id'].toString()),
                      userFullName: 'Klinisyen',
                      isModerator: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.videocam_outlined, color: Colors.white),
              label: const Text(
                'Görüşmeye Katıl',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(apt),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _updateAppointmentStatus(index, true),
                    child: _actionButton(Icons.check, Colors.green),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _updateAppointmentStatus(index, false),
                    child: _actionButton(Icons.close, Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(Map<String, dynamic> apt) {
    final approved = apt['approved'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: approved == true
            ? const Color(0xFFF0FDF4)
            : approved == false
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: approved == true
              ? Colors.green.shade200
              : approved == false
              ? Colors.red.shade200
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        approved == true
            ? 'Onaylandı'
            : approved == false
            ? 'İptal Edildi'
            : apt['status'] ?? 'Planlandı',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: approved == true
              ? Colors.green.shade700
              : approved == false
              ? Colors.red.shade700
              : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}