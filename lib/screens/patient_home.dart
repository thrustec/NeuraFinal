import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/patient.dart' as sila;
import 'telerehab_patient_screen.dart';
import 'hasta_egzersiz_screen.dart';
import 'patient_agenda_screen.dart';
import '../services/supabase_service.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  static const Color _primaryBlue = Color(0xFF2563EB);

  bool _isLoadingTodayMeetings = true;
  List<Map<String, dynamic>> _todayMeetings = [];

  bool _isLoadingTodayExercises = true;
  List<Map<String, dynamic>> _todayExercises = [];

  @override
  void initState() {
    super.initState();
    _loadTodayMeetings();
    _loadTodayExercises();
  }

  Future<int?> _getCurrentPatientId() async {
    final auth = context.read<AuthProvider>();
    final kullaniciId = int.tryParse(auth.user?.id ?? '');

    if (kullaniciId == null) {
      return null;
    }

    final patientResponse = await SupabaseService.client
        .schema('neura')
        .from('hastalar')
        .select('hastaId')
        .eq('kullaniciId', kullaniciId)
        .maybeSingle();

    if (patientResponse == null) {
      return null;
    }

    return patientResponse['hastaId'] as int?;
  }

  Future<void> _loadTodayMeetings() async {
    try {
      final hastaId = await _getCurrentPatientId();

      if (hastaId == null) {
        if (!mounted) return;
        setState(() {
          _isLoadingTodayMeetings = false;
          _todayMeetings = [];
        });
        return;
      }

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));

      final meetingsResponse = await SupabaseService.client
          .schema('neura')
          .from('toplantilar')
          .select(
        'toplantiId, hastaId, baslik, baslangicZamani, bitisZamani, durum',
      )
          .eq('hastaId', hastaId)
          .gte('baslangicZamani', todayStart.toIso8601String())
          .lt('baslangicZamani', tomorrowStart.toIso8601String())
          .neq('durum', 'İptal Edildi')
          .order('baslangicZamani', ascending: true);

      if (!mounted) return;

      setState(() {
        _todayMeetings =
        List<Map<String, dynamic>>.from(meetingsResponse);
        _isLoadingTodayMeetings = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingTodayMeetings = false;
        _todayMeetings = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bugünkü toplantılar yüklenemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _loadTodayExercises() async {
    try {
      final hastaId = await _getCurrentPatientId();

      if (hastaId == null) {
        if (!mounted) return;
        setState(() {
          _isLoadingTodayExercises = false;
          _todayExercises = [];
        });
        return;
      }

      final now = DateTime.now();
      final todayText =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      final exercisesResponse = await SupabaseService.client
          .schema('neura')
          .from('egzersizAtalari')
          .select(
        'egzersizAtamaId, hastaId, egzersizAdi, atamaTarihi, tamamlandiMi',
      )
          .eq('hastaId', hastaId)
          .eq('atamaTarihi', todayText)
          .order('egzersizAtamaId', ascending: true);

      if (!mounted) return;

      setState(() {
        _todayExercises =
        List<Map<String, dynamic>>.from(exercisesResponse);
        _isLoadingTodayExercises = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingTodayExercises = false;
        _todayExercises = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bugünkü egzersizler yüklenemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _openPatientAgenda() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final hastaId = await _getCurrentPatientId();

    if (!mounted) return;

    if (user == null || hastaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajanda bilgileri açılırken hata oluştu.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientAgendaScreen(
          patient: sila.Patient(
            hastaId: hastaId,
            kullaniciId: int.tryParse(user.id) ?? 0,
            ad: user.ad,
            soyad: user.soyad,
            tani: '',
            durum: 'Aktif Hasta',
            degerlendirmeler: const [],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(auth.user?.fullName ?? 'Değerli Hastamız'),

          const SizedBox(height: 28),

          _buildSectionHeader('Bugünkü Toplantılarım'),
          const SizedBox(height: 12),
          _buildTodayMeetingsCard(context),

          const SizedBox(height: 24),

          _buildSectionHeader('Bugünkü Görevlerim'),
          const SizedBox(height: 12),
          _buildDailyExerciseCard(context),

          const SizedBox(height: 28),

          _buildSectionHeader('Hızlı İşlemler'),
          const SizedBox(height: 12),
          _buildQuickActionsRow(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryBlue, Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hoşgeldin 👋',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monitor_heart, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'Hasta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildTodayMeetingsCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TelerehabPatientScreen(),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.video_camera_front_outlined,
                color: Color(0xFFEA580C),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isLoadingTodayMeetings
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Toplantılar yükleniyor...',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              )
                  : _todayMeetings.isEmpty
                  ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Telerehab Toplantıları',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mevcut toplantı yok',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Telerehab Toplantıları',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ..._todayMeetings.map((meeting) {
                    final startTime = DateTime.tryParse(
                      meeting['baslangicZamani']?.toString() ?? '',
                    );

                    final String hourText = startTime == null
                        ? '--:--'
                        : '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $hourText',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFCBD5E1),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyExerciseCard(BuildContext context) {
    final int totalExercises = _todayExercises.length;
    final int completedExercises = _todayExercises
        .where((exercise) => exercise['tamamlandiMi'] == true)
        .length;

    final String exerciseNames = _todayExercises
        .map((exercise) => exercise['egzersizAdi']?.toString() ?? '')
        .where((name) => name.trim().isNotEmpty)
        .join(', ');

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const HastaEgzersizScreen(),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Color(0xFF16A34A),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isLoadingTodayExercises
                  ? const Text(
                'Egzersizler yükleniyor...',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              )
                  : _todayExercises.isEmpty
                  ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bugünkü Egzersizlerim',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Bugün için atanmış egzersiz yok',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bugünkü Egzersizlerim',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exerciseNames,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '($completedExercises/$totalExercises) tamamlandı',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: _primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          const SizedBox(width: 12),
          _QuickActionTile(
            icon: Icons.video_camera_front_outlined,
            label: 'Toplantılar',
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TelerehabPatientScreen(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _QuickActionTile(
            icon: Icons.calendar_month_outlined,
            label: 'Ajanda',
            color: Colors.blue,
            onTap: _openPatientAgenda,
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}