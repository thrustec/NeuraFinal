import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme.dart';

class ClinicianAgenda extends StatefulWidget {
  const ClinicianAgenda({super.key});

  @override
  State<ClinicianAgenda> createState() => _ClinicianAgendaState();
}

class _ClinicianAgendaState extends State<ClinicianAgenda> {
  static const Color _green = Color(0xFF1DB954);
  static const String _baseUrl = 'https://griteunvazwekosffmjo.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
  };

  final TextEditingController _searchController = TextEditingController();
  String? _selectedPatientId;
  String? _selectedPatientName;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _repeat = 'Tek Sefer';

  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadPatients(), _loadAppointments()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadPatients() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/rest/v1/hastalar?select=hastaId,kullanicilar(ad,soyad)'),
        headers: _headers,
      );
      print('Patients response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _patients = data.map((p) {
            final user = p['kullanicilar'];
            return {
              'id': p['hastaId'].toString(),
              'name': user != null
                  ? '${user['ad'] ?? ''} ${user['soyad'] ?? ''}'.trim()
                  : 'Hasta ${p['hastaId']}',
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Patients error: $e');
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/rest/v1/toplantilar?select=toplantiId,baslik,baslangicZamani,notlar,hastalar(kullanicilar(ad,soyad))'),
        headers: _headers,
      );
      print('Appointments response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _appointments = data.map((t) {
            final hasta = t['hastalar']?['kullanicilar'];
            final dt = t['baslangicZamani'] != null
                ? DateTime.parse(t['baslangicZamani'])
                : null;
            return {
              'id': t['toplantiId'].toString(),
              'patient': hasta != null
                  ? '${hasta['ad'] ?? ''} ${hasta['soyad'] ?? ''}'.trim()
                  : 'Hasta',
              'diagnosis': t['baslik'] ?? '-',
              'date': dt != null
                  ? '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'
                  : '-',
              'time': dt != null
                  ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                  : '-',
              'status': 'Planlandı',
              'approved': null,
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Appointments error: $e');
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
    if (picked != null) setState(() => _selectedDate = picked);
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
    if (picked != null) setState(() => _selectedTime = picked);
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
      final response = await http.post(
        Uri.parse('$_baseUrl/rest/v1/toplantilar'),
        headers: {
          ..._headers,
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'hastaId': int.parse(_selectedPatientId!),
          'klinisyenId': 1,
          'baslik': 'Randevu',
          'baslangicZamani': dt.toIso8601String(),
          'notlar': _repeat,
        }),
      );

      print('Create appointment: ${response.statusCode} ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
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
        });
        await _loadAppointments();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${response.body}')),
        );
      }
    } catch (e) {
      print('Create error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Klinisyen Ajandası',
          style: TextStyle(
            color: _green,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: _green),
      )
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hasta Seçimi
              _SectionLabel(icon: Icons.person, label: 'Hasta'),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Hasta adı veya ID yazın...',
                  filled: true,
                  fillColor: const Color(0xFFEAF4FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPatientId,
                    hint: const Text('Bir hasta seçin'),
                    isExpanded: true,
                    items: _patients
                        .map((p) => DropdownMenuItem(
                      value: p['id'] as String,
                      child: Text(p['name'] as String),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedPatientId = val;
                        _selectedPatientName = _patients
                            .firstWhere((p) => p['id'] == val)['name'];
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tarih
              _SectionLabel(
                  icon: Icons.calendar_today, label: 'Tarih'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: _green),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDate == null
                            ? 'Tarih seçin'
                            : '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}',
                        style: TextStyle(
                          color: _selectedDate == null
                              ? NeuraTheme.textGrey
                              : NeuraTheme.textDark,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Saat
              _SectionLabel(
                  icon: Icons.access_time, label: 'Saat'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_outlined,
                          size: 16, color: _green),
                      const SizedBox(width: 8),
                      Text(
                        _selectedTime == null
                            ? 'Saat seçin'
                            : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: _selectedTime == null
                              ? NeuraTheme.textGrey
                              : NeuraTheme.textDark,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tekrar
              _SectionLabel(icon: Icons.repeat, label: 'Tekrar'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _repeat,
                    isExpanded: true,
                    items: ['Tek Sefer', 'Haftalık', 'Aylık']
                        .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r),
                    ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _repeat = val!),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Plan Oluştur Butonu
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _createPlan,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text(
                    'Plan Oluştur',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Mevcut Randevular başlık
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: NeuraTheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.calendar_month_outlined,
                            color: _green, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Mevcut Randevular',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _green,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _loadAppointments,
                      child: const Icon(Icons.refresh,
                          color: _green),
                    ),
                  ],
                ),
              ),

              // Randevu listesi boşsa
              if (_appointments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'Henüz randevu yok',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

              // Randevu kartları
              ..._appointments.asMap().entries.map((entry) {
                final i = entry.key;
                final apt = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border:
                    Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 14, color: _green),
                          const SizedBox(width: 4),
                          Text(
                            apt['patient'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            child: Text(
                              apt['diagnosis'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(apt['date'],
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey)),
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time_outlined,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(apt['time'],
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: apt['approved'] == true
                                  ? Colors.green.shade50
                                  : apt['approved'] == false
                                  ? Colors.red.shade50
                                  : Colors.blue.shade50,
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            child: Text(
                              apt['approved'] == true
                                  ? 'Onaylandı'
                                  : apt['approved'] == false
                                  ? 'İptal Edildi'
                                  : apt['status'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: apt['approved'] == true
                                    ? Colors.green
                                    : apt['approved'] == false
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() =>
                                _appointments[i]
                                ['approved'] = true),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.white,
                                      size: 18),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() =>
                                _appointments[i]
                                ['approved'] = false),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white,
                                      size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: NeuraTheme.textGrey),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: NeuraTheme.textGrey,
          ),
        ),
      ],
    );
  }
}