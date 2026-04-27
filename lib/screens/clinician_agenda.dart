import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ClinicianAgenda extends StatefulWidget {
  const ClinicianAgenda({super.key});

  @override
  State<ClinicianAgenda> createState() => _ClinicianAgendaState();
}

class _ClinicianAgendaState extends State<ClinicianAgenda> {
  // Merve'nin Klinisyen Teması
  static const Color _green = Color(0xFF0F766E);
  static const Color kBackground = Color(0xFFF8F9FC);

  static const String _baseUrl = 'https://griteunvazwekosffmjo.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Accept-Profile': 'neura',
        'Content-Profile': 'neura',
      };

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

  /// Auth'tan gelen klinisyenin kullaniciId'si.
  /// Toplantı oluştururken `klinisyenId` olarak bu değer gönderilir,
  /// çünkü `toplantilar.klinisyenId → kullanicilar.kullaniciId` FK'sini referans alır.
  int _currentClinicianUserId = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final userIdStr = auth.user?.id ?? '';
      final parsed = int.tryParse(userIdStr);
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

  // ---- MANTIK (LOGIC) KISMI ----

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadPatients(), _loadAppointments()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadPatients() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/rest/v1/hastalar?select=hastaId,kullanicilar!inner(ad,soyad)'),
        headers: _headers,
      );
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
          _filteredPatients = _patients;
        });
      } else {
        print('Patients error body: ${response.body}');
      }
    } catch (e) {
      print('Patients error: $e');
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/rest/v1/toplantilar?select=toplantiId,baslik,baslangicZamani,notlar,hastalar!inner(kullanicilar!inner(ad,soyad))&klinisyenId=eq.$_currentClinicianUserId'),
        headers: _headers,
      );
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
          'klinisyenId': _currentClinicianUserId,
          'baslik': 'Randevu',
          'baslangicZamani': dt.toIso8601String(),
          'notlar': _repeat,
        }),
      );

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
          _filteredPatients = _patients;
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

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1E293B), size: 18),
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
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.add_task, color: _green, size: 20),
                              SizedBox(width: 8),
                              Text('Yeni Plan Oluştur',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
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
                                    .where((p) =>
                                        (p['name'] as String)
                                            .toLowerCase()
                                            .contains(value.toLowerCase()) ||
                                        (p['id'] as String).contains(value))
                                    .toList();
                                if (_selectedPatientId != null) {
                                  final halaVar = _filteredPatients.any(
                                      (p) =>
                                          p['id'] == _selectedPatientId);
                                  if (!halaVar) {
                                    _selectedPatientId = null;
                                    _selectedPatientName = null;
                                  }
                                }
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Hasta adı giriniz',
                              hintStyle: const TextStyle(
                                  fontSize: 14, color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPatientId,
                                hint: const Text('Bir hasta seçin',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF94A3B8))),
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
                                    _selectedPatientName = _filteredPatients
                                            .firstWhere(
                                                (p) => p['id'] == val)['name']
                                        as String?;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _SectionLabel(
                                        icon: Icons.calendar_today,
                                        label: 'Tarih'),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _pickDate,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.calendar_today_outlined,
                                                size: 16,
                                                color: _green),
                                            const SizedBox(width: 8),
                                            Text(
                                              _selectedDate == null
                                                  ? 'Seçiniz'
                                                  : '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}',
                                              style: TextStyle(
                                                color: _selectedDate == null
                                                    ? const Color(0xFF94A3B8)
                                                    : const Color(0xFF1E293B),
                                                fontSize: 13,
                                                fontWeight:
                                                    _selectedDate == null
                                                        ? FontWeight.normal
                                                        : FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _SectionLabel(
                                        icon: Icons.access_time,
                                        label: 'Saat'),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _pickTime,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.access_time_outlined,
                                                size: 16,
                                                color: _green),
                                            const SizedBox(width: 8),
                                            Text(
                                              _selectedTime == null
                                                  ? 'Seçiniz'
                                                  : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                color: _selectedTime == null
                                                    ? const Color(0xFF94A3B8)
                                                    : const Color(0xFF1E293B),
                                                fontSize: 13,
                                                fontWeight:
                                                    _selectedTime == null
                                                        ? FontWeight.normal
                                                        : FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          _SectionLabel(icon: Icons.repeat, label: 'Tekrar'),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _repeat,
                                isExpanded: true,
                                items: ['Tek Sefer', 'Haftalık', 'Aylık']
                                    .map((r) => DropdownMenuItem(
                                        value: r, child: Text(r)))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _repeat = val!),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _createPlan,
                              icon: const Icon(Icons.save_outlined,
                                  size: 20, color: Colors.white),
                              label: const Text(
                                'Randevu Oluştur',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                    letterSpacing: 0.5),
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
                    ),

                    const SizedBox(height: 32),

                    Row(
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
                          child: const Icon(Icons.refresh,
                              color: _green, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_appointments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text(
                            'Henüz randevu yok.',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),

                    ..._appointments.asMap().entries.map((entry) {
                      final i = entry.key;
                      final apt = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8)
                            ]),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      _green.withOpacity(0.1),
                                  child: const Icon(Icons.person,
                                      size: 16, color: _green),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    apt['patient'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF1E293B)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    apt['diagnosis'],
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 14, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 6),
                                Text(apt['date'],
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B))),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time_outlined,
                                    size: 14, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 6),
                                Text(apt['time'],
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B))),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                  height: 1, color: Color(0xFFE2E8F0)),
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: apt['approved'] == true
                                          ? const Color(0xFFF0FDF4)
                                          : apt['approved'] == false
                                              ? const Color(0xFFFEF2F2)
                                              : const Color(0xFFF8FAFC),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: apt['approved'] == true
                                              ? Colors.green.shade200
                                              : apt['approved'] == false
                                                  ? Colors.red.shade200
                                                  : const Color(
                                                      0xFFE2E8F0))),
                                  child: Text(
                                    apt['approved'] == true
                                        ? 'Onaylandı'
                                        : apt['approved'] == false
                                            ? 'İptal Edildi'
                                            : apt['status'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: apt['approved'] == true
                                          ? Colors.green.shade700
                                          : apt['approved'] == false
                                              ? Colors.red.shade700
                                              : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(() =>
                                          _appointments[i]['approved'] =
                                              true),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: const Icon(Icons.check,
                                            color: Colors.white, size: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => setState(() =>
                                          _appointments[i]['approved'] =
                                              false),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 20),
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
